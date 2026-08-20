package auth

import (
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"net/http"
	"sync"
	"time"
)

var (
	ErrInvalidIDToken = errors.New("invalid identity token")
	ErrJWKSFetch      = errors.New("failed to fetch JWKS")
)

// IdentityClaims are the verified fields we need from a provider ID token.
type IdentityClaims struct {
	Subject       string
	Email         string
	EmailVerified bool
}

type jwksResponse struct {
	Keys []jwkKey `json:"keys"`
}

type jwkKey struct {
	Kid string `json:"kid"`
	Kty string `json:"kty"`
	Alg string `json:"alg"`
	Use string `json:"use"`
	N   string `json:"n"`
	E   string `json:"e"`
}

// JWKSCache fetches and caches RSA public keys from a JWKS URL.
type JWKSCache struct {
	url        string
	httpClient *http.Client
	ttl        time.Duration

	mu        sync.RWMutex
	keys      map[string]*rsa.PublicKey
	fetchedAt time.Time
}

func NewJWKSCache(url string) *JWKSCache {
	return &JWKSCache{
		url: url,
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
		ttl:  time.Hour,
		keys: make(map[string]*rsa.PublicKey),
	}
}

func (c *JWKSCache) KeyFunc(tokenKid string) (*rsa.PublicKey, error) {
	if key, ok := c.lookup(tokenKid); ok {
		return key, nil
	}
	if err := c.refresh(); err != nil {
		return nil, err
	}
	if key, ok := c.lookup(tokenKid); ok {
		return key, nil
	}
	return nil, fmt.Errorf("%w: unknown kid %q", ErrInvalidIDToken, tokenKid)
}

func (c *JWKSCache) lookup(kid string) (*rsa.PublicKey, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	if time.Since(c.fetchedAt) > c.ttl {
		return nil, false
	}
	key, ok := c.keys[kid]
	return key, ok
}

func (c *JWKSCache) refresh() error {
	c.mu.Lock()
	defer c.mu.Unlock()

	// Another goroutine may have refreshed while we waited.
	if time.Since(c.fetchedAt) <= c.ttl && len(c.keys) > 0 {
		return nil
	}

	req, err := http.NewRequest(http.MethodGet, c.url, nil)
	if err != nil {
		return fmt.Errorf("%w: %v", ErrJWKSFetch, err)
	}
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("%w: %v", ErrJWKSFetch, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("%w: status %d", ErrJWKSFetch, resp.StatusCode)
	}

	var body jwksResponse
	if err := json.NewDecoder(resp.Body).Decode(&body); err != nil {
		return fmt.Errorf("%w: decode: %v", ErrJWKSFetch, err)
	}

	next := make(map[string]*rsa.PublicKey, len(body.Keys))
	for _, k := range body.Keys {
		if k.Kty != "RSA" || k.N == "" || k.E == "" {
			continue
		}
		pub, err := rsaPublicKeyFromJWK(k.N, k.E)
		if err != nil {
			continue
		}
		next[k.Kid] = pub
	}
	if len(next) == 0 {
		return fmt.Errorf("%w: no RSA keys in JWKS", ErrJWKSFetch)
	}
	c.keys = next
	c.fetchedAt = time.Now()
	return nil
}

func rsaPublicKeyFromJWK(nB64, eB64 string) (*rsa.PublicKey, error) {
	nBytes, err := base64.RawURLEncoding.DecodeString(nB64)
	if err != nil {
		return nil, err
	}
	eBytes, err := base64.RawURLEncoding.DecodeString(eB64)
	if err != nil {
		return nil, err
	}
	var eInt int
	for _, b := range eBytes {
		eInt = eInt<<8 + int(b)
	}
	if eInt == 0 {
		return nil, errors.New("invalid exponent")
	}
	return &rsa.PublicKey{
		N: new(big.Int).SetBytes(nBytes),
		E: eInt,
	}, nil
}

func audienceAllowed(aud jwtAudiences, allowed []string) bool {
	if len(allowed) == 0 {
		return false
	}
	for _, a := range aud {
		for _, want := range allowed {
			if a == want {
				return true
			}
		}
	}
	return false
}

// jwtAudiences unmarshals JWT "aud" as string or []string.
type jwtAudiences []string

func (a *jwtAudiences) UnmarshalJSON(data []byte) error {
	var single string
	if err := json.Unmarshal(data, &single); err == nil {
		*a = []string{single}
		return nil
	}
	var many []string
	if err := json.Unmarshal(data, &many); err != nil {
		return err
	}
	*a = many
	return nil
}
