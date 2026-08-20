package service

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/radar-alert/backend/internal/client/tts"
)

func TestBucketDistance(t *testing.T) {
	cases := []struct {
		in   float64
		want int
	}{
		{0, 100},
		{80, 100},
		{100, 100},
		{101, 200},
		{150, 200},
		{200, 200},
		{250, 300},
		{300, 300},
		{400, 500},
		{500, 500},
		{750, 1000},
		{1000, 1000},
		{1200, 1000},
	}
	for _, tc := range cases {
		if got := BucketDistance(tc.in); got != tc.want {
			t.Fatalf("BucketDistance(%v)=%d want %d", tc.in, got, tc.want)
		}
	}
}

func TestResolvePhrase(t *testing.T) {
	text, err := ResolvePhrase("camera.mobile", map[string]any{"distance_m": 500})
	if err != nil {
		t.Fatal(err)
	}
	want := "Dikkat, mobil radar, 500 metre ileride."
	if text != want {
		t.Fatalf("got %q want %q", text, want)
	}

	if _, err := ResolvePhrase("camera.mobile", map[string]any{"distance_m": 437}); err == nil {
		t.Fatal("expected invalid bucket error")
	}
	if _, err := ResolvePhrase("nope", nil); err == nil {
		t.Fatal("expected unknown phrase error")
	}

	warn, err := ResolvePhrase("corridor.warn", nil)
	if err != nil || warn == "" {
		t.Fatalf("corridor.warn failed: %v %q", err, warn)
	}
}

func TestSpeakCacheHit(t *testing.T) {
	dir := t.TempDir()
	var calls int
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		calls++
		audio := base64.StdEncoding.EncodeToString([]byte("fake-mp3"))
		_ = json.NewEncoder(w).Encode(map[string]string{"audioContent": audio})
	}))
	defer srv.Close()

	client := tts.NewClient("test-key", "tr-TR-Standard-A")
	client.SetHTTPForTest(srv.URL, srv.Client())
	svc := NewTTSService(client, dir)

	req := SpeakRequest{
		PhraseKey: "report.police",
		Params:    map[string]any{"distance_m": 300},
	}

	first, err := svc.Speak(context.Background(), req)
	if err != nil {
		t.Fatal(err)
	}
	if first.CacheHit {
		t.Fatal("first speak should miss cache")
	}
	if calls != 1 {
		t.Fatalf("expected 1 google call, got %d", calls)
	}

	second, err := svc.Speak(context.Background(), req)
	if err != nil {
		t.Fatal(err)
	}
	if !second.CacheHit {
		t.Fatal("second speak should hit cache")
	}
	if calls != 1 {
		t.Fatalf("cache should prevent second google call, got %d", calls)
	}
	if string(first.Audio) != string(second.Audio) {
		t.Fatal("cached audio mismatch")
	}

	entries, err := os.ReadDir(dir)
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, e := range entries {
		if filepath.Ext(e.Name()) == ".mp3" {
			found = true
		}
	}
	if !found {
		t.Fatal("expected mp3 cache file")
	}
}

func TestSpeakUnavailable(t *testing.T) {
	svc := NewTTSService(tts.NewClient("", ""), t.TempDir())
	_, err := svc.Speak(context.Background(), SpeakRequest{PhraseKey: "corridor.warn"})
	if err != ErrTTSUnavailable {
		t.Fatalf("got %v want ErrTTSUnavailable", err)
	}
}
