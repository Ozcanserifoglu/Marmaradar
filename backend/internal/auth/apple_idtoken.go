package auth

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const appleKeysURL = "https://appleid.apple.com/auth/keys"
const appleIssuer = "https://appleid.apple.com"

type AppleIDTokenVerifier struct {
	audiences []string
	jwks      *JWKSCache
	now       func() time.Time
}

func NewAppleIDTokenVerifier(audiences []string) *AppleIDTokenVerifier {
	return &AppleIDTokenVerifier{
		audiences: audiences,
		jwks:      NewJWKSCache(appleKeysURL),
		now:       time.Now,
	}
}

func (v *AppleIDTokenVerifier) Audiences() []string {
	if v == nil {
		return nil
	}
	return v.audiences
}

type appleClaims struct {
	Email string       `json:"email"`
	Aud   jwtAudiences `json:"aud"`
	Iss   string       `json:"iss"`
	Sub   string       `json:"sub"`
	Exp   int64        `json:"exp"`
	Iat   int64        `json:"iat"`
	Nonce string       `json:"nonce"`
}

func (v *AppleIDTokenVerifier) Verify(idToken, rawNonce string) (*IdentityClaims, error) {
	idToken = strings.TrimSpace(idToken)
	rawNonce = strings.TrimSpace(rawNonce)
	if idToken == "" || rawNonce == "" {
		return nil, ErrInvalidIDToken
	}
	if len(v.audiences) == 0 {
		return nil, fmt.Errorf("%w: apple oauth client ids not configured", ErrInvalidIDToken)
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
	var claims appleClaims
	if err := jsonUnmarshal(raw, &claims); err != nil {
		return nil, ErrInvalidIDToken
	}

	if claims.Sub == "" || claims.Iss != appleIssuer {
		return nil, ErrInvalidIDToken
	}
	if !audienceAllowed(claims.Aud, v.audiences) {
		return nil, ErrInvalidIDToken
	}
	now := v.now().Unix()
	if claims.Exp == 0 || now >= claims.Exp {
		return nil, ErrInvalidIDToken
	}

	wantNonce := sha256Hex(rawNonce)
	if claims.Nonce == "" || !secureEqual(claims.Nonce, wantNonce) {
		return nil, ErrInvalidIDToken
	}

	email := strings.ToLower(strings.TrimSpace(claims.Email))
	// Apple only includes email on first authorization; treat present email as verified.
	verified := email != ""

	return &IdentityClaims{
		Subject:       claims.Sub,
		Email:         email,
		EmailVerified: verified,
	}, nil
}

func sha256Hex(s string) string {
	sum := sha256.Sum256([]byte(s))
	return hex.EncodeToString(sum[:])
}

func secureEqual(a, b string) bool {
	if len(a) != len(b) {
		return false
	}
	var v byte
	for i := 0; i < len(a); i++ {
		v |= a[i] ^ b[i]
	}
	return v == 0
}

func jsonMarshalMap(m jwt.MapClaims) ([]byte, error) {
	return json.Marshal(m)
}

func jsonUnmarshal(data []byte, v any) error {
	return json.Unmarshal(data, v)
}
