package auth

import (
	"fmt"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const googleCertsURL = "https://www.googleapis.com/oauth2/v3/certs"

var googleIssuers = map[string]struct{}{
	"accounts.google.com":         {},
	"https://accounts.google.com": {},
}

type GoogleIDTokenVerifier struct {
	audiences []string
	jwks      *JWKSCache
	now       func() time.Time
}

func NewGoogleIDTokenVerifier(audiences []string) *GoogleIDTokenVerifier {
	return &GoogleIDTokenVerifier{
		audiences: audiences,
		jwks:      NewJWKSCache(googleCertsURL),
		now:       time.Now,
	}
}

func (v *GoogleIDTokenVerifier) Audiences() []string {
	if v == nil {
		return nil
	}
	return v.audiences
}

type googleClaims struct {
	Email         string       `json:"email"`
	EmailVerified boolish      `json:"email_verified"`
	Aud           jwtAudiences `json:"aud"`
	Iss           string       `json:"iss"`
	Sub           string       `json:"sub"`
	Exp           int64        `json:"exp"`
	Iat           int64        `json:"iat"`
}

// boolish accepts JSON true/false or "true"/"false" (Google sometimes uses strings).
type boolish bool

func (b *boolish) UnmarshalJSON(data []byte) error {
	s := strings.Trim(string(data), `"`)
	switch s {
	case "true", "1":
		*b = true
	case "false", "0", "":
		*b = false
	default:
		*b = false
	}
	return nil
}

func (v *GoogleIDTokenVerifier) Verify(idToken string) (*IdentityClaims, error) {
	idToken = strings.TrimSpace(idToken)
	if idToken == "" {
		return nil, ErrInvalidIDToken
	}
	if len(v.audiences) == 0 {
		return nil, fmt.Errorf("%w: google oauth client ids not configured", ErrInvalidIDToken)
	}

	parser := jwt.NewParser(
		jwt.WithValidMethods([]string{jwt.SigningMethodRS256.Alg()}),
		jwt.WithoutClaimsValidation(),
	)
	token, err := parser.Parse(idToken, func(t *jwt.Token) (any, error) {
		kid, _ := t.Header["kid"].(string)
		if kid == "" {
			return nil, fmt.Errorf("%w: missing kid", ErrInvalidIDToken)
		}
		return v.jwks.KeyFunc(kid)
	})
	if err != nil || !token.Valid {
		return nil, ErrInvalidIDToken
	}

	mapClaims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, ErrInvalidIDToken
	}
	raw, err := jsonMarshalMap(mapClaims)
	if err != nil {
		return nil, ErrInvalidIDToken
	}
	var claims googleClaims
	if err := jsonUnmarshal(raw, &claims); err != nil {
		return nil, ErrInvalidIDToken
	}

	if claims.Sub == "" {
		return nil, ErrInvalidIDToken
	}
	if _, ok := googleIssuers[claims.Iss]; !ok {
		return nil, ErrInvalidIDToken
	}
	if !audienceAllowed(claims.Aud, v.audiences) {
		return nil, ErrInvalidIDToken
	}
	now := v.now().Unix()
	if claims.Exp == 0 || now >= claims.Exp {
		return nil, ErrInvalidIDToken
	}

	email := strings.ToLower(strings.TrimSpace(claims.Email))
	verified := bool(claims.EmailVerified)
	if email == "" {
		verified = false
	}

	return &IdentityClaims{
		Subject:       claims.Sub,
		Email:         email,
		EmailVerified: verified,
	}, nil
}
