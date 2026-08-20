package auth

import (
	"crypto/rand"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"math/big"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

func TestAudienceAllowed(t *testing.T) {
	allowed := []string{"web.apps.googleusercontent.com", "com.radaralert.radarAlert"}
	if !audienceAllowed(jwtAudiences{"web.apps.googleusercontent.com"}, allowed) {
		t.Fatal("expected web audience allowed")
	}
	if audienceAllowed(jwtAudiences{"other"}, allowed) {
		t.Fatal("expected other audience rejected")
	}
	if audienceAllowed(jwtAudiences{"web.apps.googleusercontent.com"}, nil) {
		t.Fatal("empty allow-list must reject")
	}
}

func TestGoogleIDTokenVerifier(t *testing.T) {
	priv, pubJWK, kid := mustTestRSAKey(t)
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_ = json.NewEncoder(w).Encode(jwksResponse{Keys: []jwkKey{pubJWK}})
	}))
	t.Cleanup(srv.Close)

	aud := "123-web.apps.googleusercontent.com"
	v := NewGoogleIDTokenVerifier([]string{aud})
	v.jwks = NewJWKSCache(srv.URL)
	v.now = func() time.Time { return time.Unix(1_700_000_000, 0) }

	token := signTestJWT(t, priv, kid, map[string]any{
		"iss":            "https://accounts.google.com",
		"aud":            aud,
		"sub":            "google-sub-1",
		"email":          "User@Example.com",
		"email_verified": true,
		"iat":            1_699_999_000,
		"exp":            1_700_000_600,
	})

	claims, err := v.Verify(token)
	if err != nil {
		t.Fatalf("verify: %v", err)
	}
	if claims.Subject != "google-sub-1" || claims.Email != "user@example.com" || !claims.EmailVerified {
		t.Fatalf("unexpected claims: %+v", claims)
	}

	if _, err := v.Verify(signTestJWT(t, priv, kid, map[string]any{
		"iss": "https://accounts.google.com",
		"aud": "wrong-aud",
		"sub": "google-sub-1",
		"exp": 1_700_000_600,
	})); err == nil {
		t.Fatal("expected audience rejection")
	}
}

func TestAppleIDTokenVerifierNonce(t *testing.T) {
	priv, pubJWK, kid := mustTestRSAKey(t)
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_ = json.NewEncoder(w).Encode(jwksResponse{Keys: []jwkKey{pubJWK}})
	}))
	t.Cleanup(srv.Close)

	aud := "com.radaralert.radarAlert"
	rawNonce := "client-raw-nonce-value"
	v := NewAppleIDTokenVerifier([]string{aud})
	v.jwks = NewJWKSCache(srv.URL)
	v.now = func() time.Time { return time.Unix(1_700_000_000, 0) }

	token := signTestJWT(t, priv, kid, map[string]any{
		"iss":   appleIssuer,
		"aud":   aud,
		"sub":   "apple-sub-1",
		"email": "hide@privaterelay.appleid.com",
		"nonce": sha256Hex(rawNonce),
		"iat":   1_699_999_000,
		"exp":   1_700_000_600,
	})

	claims, err := v.Verify(token, rawNonce)
	if err != nil {
		t.Fatalf("verify: %v", err)
	}
	if claims.Subject != "apple-sub-1" || !claims.EmailVerified {
		t.Fatalf("unexpected claims: %+v", claims)
	}

	if _, err := v.Verify(token, "wrong-nonce"); err == nil {
		t.Fatal("expected nonce rejection")
	}
	if _, err := v.Verify(token, ""); err == nil {
		t.Fatal("expected empty nonce rejection")
	}
}

func mustTestRSAKey(t *testing.T) (*rsa.PrivateKey, jwkKey, string) {
	t.Helper()
	priv, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	kid := "test-kid"
	n := base64.RawURLEncoding.EncodeToString(priv.N.Bytes())
	e := base64.RawURLEncoding.EncodeToString(big.NewInt(int64(priv.E)).Bytes())
	return priv, jwkKey{Kid: kid, Kty: "RSA", Alg: "RS256", Use: "sig", N: n, E: e}, kid
}

func signTestJWT(t *testing.T, priv *rsa.PrivateKey, kid string, claims map[string]any) string {
	t.Helper()
	token := jwt.NewWithClaims(jwt.SigningMethodRS256, jwt.MapClaims(claims))
	token.Header["kid"] = kid
	signed, err := token.SignedString(priv)
	if err != nil {
		t.Fatal(err)
	}
	return signed
}
