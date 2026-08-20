package service

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"strings"
	"testing"
)

func TestHashTokenStable(t *testing.T) {
	t.Parallel()
	sum := sha256.Sum256([]byte("plain-token"))
	want := hex.EncodeToString(sum[:])
	if got := hashToken("plain-token"); got != want {
		t.Fatalf("hashToken=%s want %s", got, want)
	}
	if hashToken("a") == hashToken("b") {
		t.Fatal("different tokens must not collide")
	}
}

func TestForgotPasswordSkipsUndeliverableWithoutDB(t *testing.T) {
	t.Parallel()
	s := NewAuthService(nil, nil, nil, nil, nil, "https://marmaradar.com")
	if err := s.ForgotPassword(context.Background(), ""); err != nil {
		t.Fatalf("empty email: %v", err)
	}
	if err := s.ForgotPassword(context.Background(), "not-an-email"); err != nil {
		t.Fatalf("invalid email: %v", err)
	}
	if err := s.ForgotPassword(context.Background(), "apple.abc@oauth.local"); err != nil {
		t.Fatalf("oauth placeholder: %v", err)
	}
}

func TestResetPasswordValidation(t *testing.T) {
	t.Parallel()
	s := NewAuthService(nil, nil, nil, nil, nil, "")
	if err := s.ResetPassword(context.Background(), "", "newpassword1"); !errors.Is(err, ErrInvalidResetToken) {
		t.Fatalf("empty token: %v", err)
	}
	err := s.ResetPassword(context.Background(), "token", "short")
	if err == nil || !strings.Contains(err.Error(), "8") {
		t.Fatalf("short password: %v", err)
	}
}
