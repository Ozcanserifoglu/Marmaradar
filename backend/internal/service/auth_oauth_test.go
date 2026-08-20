package service

import (
	"strings"
	"testing"
)

func TestSyntheticOAuthEmailStable(t *testing.T) {
	t.Parallel()
	a := syntheticOAuthEmail("apple", "sub.with.dots")
	b := syntheticOAuthEmail("apple", "sub.with.dots")
	if a != b {
		t.Fatalf("expected stable email, got %q vs %q", a, b)
	}
	if !strings.HasPrefix(a, "apple.") || !strings.HasSuffix(a, "@oauth.local") {
		t.Fatalf("unexpected email shape: %q", a)
	}
	other := syntheticOAuthEmail("google", "sub.with.dots")
	if a == other {
		t.Fatal("different providers must not collide")
	}
}
