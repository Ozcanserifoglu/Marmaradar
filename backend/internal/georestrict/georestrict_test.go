package georestrict

import (
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestNewDisabledWhenEmpty(t *testing.T) {
	g, err := New(nil)
	if err != nil {
		t.Fatal(err)
	}
	if g != nil {
		t.Fatal("expected nil guard when no countries are configured")
	}
}

func TestNewRejectsUnknownCountry(t *testing.T) {
	_, err := New([]string{"US"})
	if err == nil {
		t.Fatal("expected error for unsupported country")
	}
}

func TestAllowedTurkeyCIDRs(t *testing.T) {
	g, err := New([]string{"TR"})
	if err != nil {
		t.Fatal(err)
	}

	cases := []struct {
		ip      string
		allowed bool
	}{
		{"127.0.0.1", true},
		{"10.0.0.8", true},
		{"192.168.1.20", true},
		{"172.18.0.2", true},
		{"::1", true},
		{"5.24.0.1", true}, // TR: 5.24.0.0/14
		{"8.8.8.8", false},
		{"1.1.1.1", false},
		{"2001:678:1a4::1", true},
		{"2001:4860:4860::8888", false},
	}

	for _, tc := range cases {
		ip := net.ParseIP(tc.ip)
		if ip == nil {
			t.Fatalf("bad test ip %s", tc.ip)
		}
		if got := g.Allowed(ip); got != tc.allowed {
			t.Errorf("Allowed(%s) = %v, want %v", tc.ip, got, tc.allowed)
		}
	}
}

func TestMiddlewareBlocksForeignPublicIP(t *testing.T) {
	g, err := New([]string{"TR"})
	if err != nil {
		t.Fatal(err)
	}
	ok := g.Middleware(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))

	req := httptest.NewRequest(http.MethodGet, "/v1/sync", nil)
	req.RemoteAddr = "8.8.8.8:12345"
	rec := httptest.NewRecorder()
	ok.ServeHTTP(rec, req)
	if rec.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want 403", rec.Code)
	}
}

func TestMiddlewareAllowsHealthFromAnywhere(t *testing.T) {
	g, err := New([]string{"TR"})
	if err != nil {
		t.Fatal(err)
	}
	ok := g.Middleware(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"status":"ok"}`))
	}))

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	req.RemoteAddr = "8.8.8.8:12345"
	rec := httptest.NewRecorder()
	ok.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200", rec.Code)
	}
}

func TestMiddlewareTrustsForwardedForFromPrivateHop(t *testing.T) {
	g, err := New([]string{"TR"})
	if err != nil {
		t.Fatal(err)
	}
	ok := g.Middleware(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))

	req := httptest.NewRequest(http.MethodGet, "/v1/sync", nil)
	req.RemoteAddr = "172.18.0.2:8080"
	req.Header.Set("X-Forwarded-For", "8.8.8.8")
	rec := httptest.NewRecorder()
	ok.ServeHTTP(rec, req)
	if rec.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want 403 for foreign X-Forwarded-For", rec.Code)
	}

	req = httptest.NewRequest(http.MethodGet, "/v1/sync", nil)
	req.RemoteAddr = "172.18.0.2:8080"
	req.Header.Set("X-Forwarded-For", "5.24.0.1")
	rec = httptest.NewRecorder()
	ok.ServeHTTP(rec, req)
	if rec.Code != http.StatusNoContent {
		body, _ := io.ReadAll(rec.Body)
		t.Fatalf("status = %d, want 204 for Turkish X-Forwarded-For; body=%s", rec.Code, body)
	}
}

// A client can prepend its own X-Forwarded-For before the proxy appends the
// real address, so only the last entry may decide the verdict.
func TestMiddlewareIgnoresClientSuppliedForwardedForPrefix(t *testing.T) {
	g, err := New([]string{"TR"})
	if err != nil {
		t.Fatal(err)
	}
	ok := g.Middleware(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))

	// Client claims Turkey, proxy appends the real foreign address.
	req := httptest.NewRequest(http.MethodGet, "/v1/sync", nil)
	req.RemoteAddr = "172.18.0.2:8080"
	req.Header.Add("X-Forwarded-For", "5.24.0.1")
	req.Header.Add("X-Forwarded-For", "8.8.8.8")
	rec := httptest.NewRecorder()
	ok.ServeHTTP(rec, req)
	if rec.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want 403; a spoofed Turkish prefix must not win", rec.Code)
	}

	// Same, but within a single comma-separated header.
	req = httptest.NewRequest(http.MethodGet, "/v1/sync", nil)
	req.RemoteAddr = "172.18.0.2:8080"
	req.Header.Set("X-Forwarded-For", "5.24.0.1, 8.8.8.8")
	rec = httptest.NewRecorder()
	ok.ServeHTTP(rec, req)
	if rec.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want 403 for spoofed prefix in one header", rec.Code)
	}

	// A genuine Turkish client behind the proxy still gets through.
	req = httptest.NewRequest(http.MethodGet, "/v1/sync", nil)
	req.RemoteAddr = "172.18.0.2:8080"
	req.Header.Add("X-Forwarded-For", "8.8.8.8")
	req.Header.Add("X-Forwarded-For", "5.24.0.1")
	rec = httptest.NewRecorder()
	ok.ServeHTTP(rec, req)
	if rec.Code != http.StatusNoContent {
		t.Fatalf("status = %d, want 204 when the proxy-appended address is Turkish", rec.Code)
	}
}

func TestMiddlewareIgnoresSpoofedForwardedForOnPublicHop(t *testing.T) {
	g, err := New([]string{"TR"})
	if err != nil {
		t.Fatal(err)
	}
	ok := g.Middleware(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))

	req := httptest.NewRequest(http.MethodGet, "/v1/sync", nil)
	req.RemoteAddr = "8.8.8.8:12345"
	req.Header.Set("X-Forwarded-For", "5.24.0.1")
	rec := httptest.NewRecorder()
	ok.ServeHTTP(rec, req)
	if rec.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want 403 when public client spoofs X-Forwarded-For", rec.Code)
	}
}

func TestMiddlewarePrefersCFConnectingIPOverForwardedFor(t *testing.T) {
	g, err := New([]string{"TR"})
	if err != nil {
		t.Fatal(err)
	}
	ok := g.Middleware(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))

	// Cloudflare edge in X-Forwarded-For, real Turkish visitor in CF-Connecting-IP.
	req := httptest.NewRequest(http.MethodGet, "/v1/sync", nil)
	req.RemoteAddr = "172.18.0.2:8080"
	req.Header.Set("X-Forwarded-For", "1.1.1.1")
	req.Header.Set("CF-Connecting-IP", "5.24.0.1")
	rec := httptest.NewRecorder()
	ok.ServeHTTP(rec, req)
	if rec.Code != http.StatusNoContent {
		body, _ := io.ReadAll(rec.Body)
		t.Fatalf("status = %d, want 204 when CF-Connecting-IP is Turkish; body=%s", rec.Code, body)
	}

	req = httptest.NewRequest(http.MethodGet, "/v1/sync", nil)
	req.RemoteAddr = "172.18.0.2:8080"
	req.Header.Set("X-Forwarded-For", "5.24.0.1")
	req.Header.Set("CF-Connecting-IP", "8.8.8.8")
	rec = httptest.NewRecorder()
	ok.ServeHTTP(rec, req)
	if rec.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want 403 when CF-Connecting-IP is foreign", rec.Code)
	}
}

func TestMiddlewareIgnoresSpoofedCFConnectingIPOnPublicHop(t *testing.T) {
	g, err := New([]string{"TR"})
	if err != nil {
		t.Fatal(err)
	}
	ok := g.Middleware(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))

	req := httptest.NewRequest(http.MethodGet, "/v1/sync", nil)
	req.RemoteAddr = "8.8.8.8:12345"
	req.Header.Set("CF-Connecting-IP", "5.24.0.1")
	rec := httptest.NewRecorder()
	ok.ServeHTTP(rec, req)
	if rec.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want 403 when public client spoofs CF-Connecting-IP", rec.Code)
	}
}

func TestMiddlewareFallsBackToForwardedForWithoutCFConnectingIP(t *testing.T) {
	g, err := New([]string{"TR"})
	if err != nil {
		t.Fatal(err)
	}
	ok := g.Middleware(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	}))

	req := httptest.NewRequest(http.MethodGet, "/v1/sync", nil)
	req.RemoteAddr = "172.18.0.2:8080"
	req.Header.Set("X-Forwarded-For", "5.24.0.1")
	rec := httptest.NewRecorder()
	ok.ServeHTTP(rec, req)
	if rec.Code != http.StatusNoContent {
		t.Fatalf("status = %d, want 204 falling back to X-Forwarded-For", rec.Code)
	}
}

func TestParseCountries(t *testing.T) {
	got := ParseCountries(" tr ,TR, ")
	if len(got) != 2 || got[0] != "tr" || got[1] != "TR" {
		t.Fatalf("ParseCountries = %#v", got)
	}
	if ParseCountries("  ") != nil {
		t.Fatal("expected nil for blank input")
	}
}
