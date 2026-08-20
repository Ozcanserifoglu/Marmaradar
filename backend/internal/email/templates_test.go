package email

import (
	"strings"
	"testing"
)

func TestDeliverable(t *testing.T) {
	t.Parallel()
	cases := []struct {
		in   string
		want bool
	}{
		{"user@example.com", true},
		{"  USER@Example.COM  ", true},
		{"", false},
		{"not-an-email", false},
		{"google.abc@oauth.local", false},
		{"apple.xyz@oauth.local", false},
	}
	for _, tc := range cases {
		if got := Deliverable(tc.in); got != tc.want {
			t.Errorf("Deliverable(%q)=%v want %v", tc.in, got, tc.want)
		}
	}
}

func TestResetPasswordURL(t *testing.T) {
	t.Parallel()
	got := ResetPasswordURL("https://marmaradar.com/", "abc def")
	want := "https://marmaradar.com/reset-password?token=abc+def"
	if got != want {
		t.Fatalf("got %q want %q", got, want)
	}
	if ResetPasswordURL("", "tok") != "https://marmaradar.com/reset-password?token=tok" {
		t.Fatalf("empty base should fall back, got %q", ResetPasswordURL("", "tok"))
	}
}

func TestRenderWelcome(t *testing.T) {
	t.Parallel()
	msg, err := renderWelcome("user@example.com")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(msg.Subject, "hoş geldiniz") {
		t.Fatalf("subject=%q", msg.Subject)
	}
	if !strings.Contains(msg.HTML, "user@example.com") || !strings.Contains(msg.Text, "user@example.com") {
		t.Fatal("welcome templates should include recipient")
	}
	if strings.Contains(msg.HTML, "token=") {
		t.Fatal("welcome email must not include a reset token")
	}
	assertBrandHTML(t, msg.HTML)
}

func TestRenderWelcomeEscapesHTML(t *testing.T) {
	t.Parallel()
	msg, err := renderWelcome(`a<b@example.com`)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(msg.HTML, "<b@") {
		t.Fatalf("html not escaped: %s", msg.HTML)
	}
	if !strings.Contains(msg.HTML, "a&lt;b@example.com") {
		t.Fatalf("expected escaped email in html, got %s", msg.HTML)
	}
}

func TestRenderPasswordReset(t *testing.T) {
	t.Parallel()
	url := "https://marmaradar.com/reset-password?token=secret-token"
	msg, err := renderPasswordReset(url)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(msg.HTML, url) || !strings.Contains(msg.Text, url) {
		t.Fatal("reset templates should include the reset URL")
	}
	if strings.Contains(msg.HTML, "re_") {
		t.Fatal("templates must not contain api keys")
	}
	assertBrandHTML(t, msg.HTML)
}

func TestRenderNotification(t *testing.T) {
	t.Parallel()
	msg, err := renderNotification("Kampanya", "Yeni özellik", "Haritada canlı bildirimler.")
	if err != nil {
		t.Fatal(err)
	}
	if msg.Subject != "Kampanya" {
		t.Fatalf("subject=%q", msg.Subject)
	}
	if !strings.Contains(msg.HTML, "Yeni özellik") || !strings.Contains(msg.Text, "Haritada canlı bildirimler.") {
		t.Fatal("notification body missing")
	}
	assertBrandHTML(t, msg.HTML)
}

func assertBrandHTML(t *testing.T, html string) {
	t.Helper()
	for _, needle := range []string{"MARMARADAR", "#E8262D", "#0B0B0D", "#161619"} {
		if !strings.Contains(html, needle) {
			t.Fatalf("brand html missing %q", needle)
		}
	}
	if strings.Contains(html, "<style") {
		t.Fatal("email clients strip style tags; use inline CSS only")
	}
}
