package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/radar-alert/backend/internal/service"
)

func TestForgotPasswordInvalidJSON(t *testing.T) {
	t.Parallel()
	h := NewAuthHandler(service.NewAuthService(nil, nil, nil, nil, nil, ""))
	req := httptest.NewRequest(http.MethodPost, "/v1/auth/forgot-password", strings.NewReader("{"))
	rec := httptest.NewRecorder()
	h.ForgotPassword(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status=%d", rec.Code)
	}
}

func TestForgotPasswordAlwaysOKForUndeliverable(t *testing.T) {
	t.Parallel()
	h := NewAuthHandler(service.NewAuthService(nil, nil, nil, nil, nil, ""))
	req := httptest.NewRequest(http.MethodPost, "/v1/auth/forgot-password", strings.NewReader(`{"email":"nobody@oauth.local"}`))
	rec := httptest.NewRecorder()
	h.ForgotPassword(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
	}
	var body map[string]bool
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatal(err)
	}
	if !body["ok"] {
		t.Fatalf("body=%v", body)
	}
}

func TestResetPasswordInvalidToken(t *testing.T) {
	t.Parallel()
	h := NewAuthHandler(service.NewAuthService(nil, nil, nil, nil, nil, ""))
	req := httptest.NewRequest(http.MethodPost, "/v1/auth/reset-password", strings.NewReader(`{"token":"","password":"newpassword1"}`))
	rec := httptest.NewRecorder()
	h.ResetPassword(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
	}
}

func TestResetPasswordShortPassword(t *testing.T) {
	t.Parallel()
	h := NewAuthHandler(service.NewAuthService(nil, nil, nil, nil, nil, ""))
	req := httptest.NewRequest(http.MethodPost, "/v1/auth/reset-password", strings.NewReader(`{"token":"abc","password":"short"}`))
	rec := httptest.NewRecorder()
	h.ResetPassword(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
	}
}
