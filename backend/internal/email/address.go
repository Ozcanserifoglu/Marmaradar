package email

import (
	"net/url"
	"strings"
)

const oauthLocalSuffix = "@oauth.local"

// Deliverable reports whether the address is a real mailbox we should mail.
// Synthetic OAuth placeholders (…@oauth.local) are skipped.
func Deliverable(address string) bool {
	address = strings.ToLower(strings.TrimSpace(address))
	if address == "" || !strings.Contains(address, "@") {
		return false
	}
	return !strings.HasSuffix(address, oauthLocalSuffix)
}

// ResetPasswordURL builds the password-reset link for the given app base URL.
func ResetPasswordURL(baseURL, token string) string {
	base := strings.TrimRight(strings.TrimSpace(baseURL), "/")
	if base == "" {
		base = "https://marmaradar.com"
	}
	return base + "/reset-password?token=" + url.QueryEscape(token)
}
