package handler

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestResetPasswordPage(t *testing.T) {
	t.Parallel()
	h := NewAuthHandler(nil)
	req := httptest.NewRequest(http.MethodGet, "/reset-password?token=abc", nil)
	rec := httptest.NewRecorder()
	h.ResetPasswordPage(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("status=%d", rec.Code)
	}
	ct := rec.Header().Get("Content-Type")
	if !strings.Contains(ct, "text/html") {
		t.Fatalf("content-type=%q", ct)
	}
	body := rec.Body.String()
	if !strings.Contains(body, "MARMARADAR") || !strings.Contains(body, "#E8262D") {
		t.Fatal("reset page missing brand markup")
	}
	if !strings.Contains(body, "/v1/auth/reset-password") {
		t.Fatal("reset page must post to the reset API")
	}
}
