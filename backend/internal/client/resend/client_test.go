package resend

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestDisabledWithoutKey(t *testing.T) {
	t.Parallel()
	c := NewClient("")
	if c.Enabled() {
		t.Fatal("expected disabled without key")
	}
	if err := c.Send(context.Background(), Message{From: "a@b.com", To: []string{"c@d.com"}, Subject: "hi"}); err == nil {
		t.Fatal("expected error when key is missing")
	}
}

func TestSendOK(t *testing.T) {
	t.Parallel()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			t.Errorf("method=%s", r.Method)
		}
		if got := r.Header.Get("Authorization"); got != "Bearer test-key" {
			t.Errorf("authorization=%q", got)
		}
		if got := r.Header.Get("Content-Type"); got != "application/json" {
			t.Errorf("content-type=%q", got)
		}
		body, err := io.ReadAll(r.Body)
		if err != nil {
			t.Errorf("read body: %v", err)
			return
		}
		var payload map[string]any
		if err := json.Unmarshal(body, &payload); err != nil {
			t.Errorf("json: %v", err)
			return
		}
		if payload["from"] != "Marmaradar <noreply@marmaradar.com>" {
			t.Errorf("from=%v", payload["from"])
		}
		if payload["subject"] != "hello" {
			t.Errorf("subject=%v", payload["subject"])
		}
		if payload["reply_to"] != "support@marmaradar.com" {
			t.Errorf("reply_to=%v", payload["reply_to"])
		}
		to, _ := payload["to"].([]any)
		if len(to) != 1 || to[0] != "user@example.com" {
			t.Errorf("to=%v", payload["to"])
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"id":"msg_1"}`))
	}))
	defer srv.Close()

	c := NewClient("test-key")
	c.SetHTTPForTest(srv.URL, srv.Client())
	err := c.Send(context.Background(), Message{
		From:    "Marmaradar <noreply@marmaradar.com>",
		To:      []string{" user@example.com "},
		Subject: "hello",
		HTML:    "<p>hi</p>",
		Text:    "hi",
		ReplyTo: "support@marmaradar.com",
	})
	if err != nil {
		t.Fatalf("Send: %v", err)
	}
}

func TestSendHTTPError(t *testing.T) {
	t.Parallel()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
		_, _ = w.Write([]byte(`{"statusCode":401,"name":"validation_error","message":"API key is invalid"}`))
	}))
	defer srv.Close()

	c := NewClient("test-key")
	c.SetHTTPForTest(srv.URL, srv.Client())
	err := c.Send(context.Background(), Message{
		From:    "a@b.com",
		To:      []string{"c@d.com"},
		Subject: "hello",
	})
	if err == nil {
		t.Fatal("expected error")
	}
	if !strings.Contains(err.Error(), "401") || !strings.Contains(err.Error(), "API key is invalid") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestSendRequiresToAndSubject(t *testing.T) {
	t.Parallel()
	c := NewClient("test-key")
	if err := c.Send(context.Background(), Message{From: "a@b.com", Subject: "x"}); err == nil {
		t.Fatal("expected empty to error")
	}
	if err := c.Send(context.Background(), Message{From: "a@b.com", To: []string{"c@d.com"}}); err == nil {
		t.Fatal("expected empty subject error")
	}
}
