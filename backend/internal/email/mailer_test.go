package email

import (
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"
	"time"

	"github.com/radar-alert/backend/internal/client/resend"
)

func TestMailerDisabledWithoutKey(t *testing.T) {
	t.Parallel()
	m := NewMailer(resend.NewClient(""), "", "")
	if m.Enabled() {
		t.Fatal("expected disabled mailer")
	}
	m.EnqueueWelcome("user@example.com")
	m.EnqueuePasswordReset("user@example.com", "https://example.com/reset")
	m.EnqueueNotification("user@example.com", "Konu", "Başlık", "Gövde")
}

func TestNilMailerEnabled(t *testing.T) {
	t.Parallel()
	var m *Mailer
	if m.Enabled() {
		t.Fatal("nil mailer should be disabled")
	}
	m.EnqueueWelcome("user@example.com")
}

func TestEnqueueSkipsSyntheticAndFillsQueueWithoutBlocking(t *testing.T) {
	t.Parallel()
	c := resend.NewClient("test-key")
	m := newMailer(c, "Marmaradar <noreply@marmaradar.com>", "support@marmaradar.com", 1, 0)

	m.EnqueueWelcome("google.abc@oauth.local")
	if len(m.jobs) != 0 {
		t.Fatal("synthetic oauth addresses must not be queued")
	}

	m.EnqueueWelcome("one@example.com")
	if len(m.jobs) != 1 {
		t.Fatalf("want 1 queued job, got %d", len(m.jobs))
	}

	done := make(chan struct{})
	go func() {
		m.EnqueueWelcome("two@example.com")
		close(done)
	}()
	select {
	case <-done:
	case <-time.After(time.Second):
		t.Fatal("enqueue blocked on full queue")
	}
}

func TestMailerSendsWelcome(t *testing.T) {
	t.Parallel()
	var hits atomic.Int32
	got := make(chan map[string]any, 1)
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		hits.Add(1)
		body, _ := io.ReadAll(r.Body)
		var payload map[string]any
		_ = json.Unmarshal(body, &payload)
		got <- payload
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"id":"1"}`))
	}))
	defer srv.Close()

	c := resend.NewClient("test-key")
	c.SetHTTPForTest(srv.URL, srv.Client())
	m := newMailer(c, "Marmaradar <noreply@marmaradar.com>", "support@marmaradar.com", 8, 1)
	m.EnqueueWelcome("user@example.com")

	select {
	case payload := <-got:
		if payload["subject"] != "Marmaradar'a hoş geldiniz" {
			t.Fatalf("subject=%v", payload["subject"])
		}
		html, _ := payload["html"].(string)
		if html == "" {
			t.Fatal("expected html body")
		}
	case <-time.After(2 * time.Second):
		t.Fatalf("email was not sent, hits=%d", hits.Load())
	}
}
