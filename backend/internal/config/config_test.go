package config

import (
	"reflect"
	"testing"
)

func TestClientIDCSVParsing(t *testing.T) {
	t.Parallel()
	cfg := Config{
		GoogleOAuthClientIDs: " web-id , ios-id,,android-id ",
		AppleOAuthClientIDs:  "com.radaralert.radarAlert",
	}
	gotGoogle := cfg.GoogleClientIDs()
	wantGoogle := []string{"web-id", "ios-id", "android-id"}
	if !reflect.DeepEqual(gotGoogle, wantGoogle) {
		t.Fatalf("GoogleClientIDs=%v want %v", gotGoogle, wantGoogle)
	}
	gotApple := cfg.AppleClientIDs()
	wantApple := []string{"com.radaralert.radarAlert"}
	if !reflect.DeepEqual(gotApple, wantApple) {
		t.Fatalf("AppleClientIDs=%v want %v", gotApple, wantApple)
	}
	if len((Config{}).GoogleClientIDs()) != 0 {
		t.Fatal("empty config should yield no audiences")
	}
}
