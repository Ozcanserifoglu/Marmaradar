package handler

import (
	_ "embed"
	"net/http"
)

//go:embed reset_password_page.html
var resetPasswordPage []byte

func (h *AuthHandler) ResetPasswordPage(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write(resetPasswordPage)
}
