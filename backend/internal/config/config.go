package config

import (
	"fmt"
	"os"
	"strings"

	"github.com/kelseyhightower/envconfig"
)

// DevJWTSecret signs tokens when JWT_SECRET is unset. It is published in this
// repo, so any reachable deployment using it can have tokens forged.
const DevJWTSecret = "dev-only-change-me-in-production"

type Config struct {
	DatabaseURL          string `envconfig:"DATABASE_URL" required:"true"`
	Port                 string `envconfig:"PORT" default:"8080"`
	MigrationsDir        string `envconfig:"MIGRATIONS_DIR"`
	JWTSecret            string `envconfig:"JWT_SECRET"`
	AccessTokenTTL       int    `envconfig:"ACCESS_TOKEN_TTL" default:"900"`
	RefreshTokenTTL      int    `envconfig:"REFRESH_TOKEN_TTL" default:"2592000"`
	GoogleOAuthClientIDs string `envconfig:"GOOGLE_OAUTH_CLIENT_IDS"`
	AppleOAuthClientIDs  string `envconfig:"APPLE_OAUTH_CLIENT_IDS"`
	GoogleMapsAPIKey     string `envconfig:"GOOGLE_MAPS_API_KEY"`
	GoogleTTSAPIKey      string `envconfig:"GOOGLE_TTS_API_KEY"`
	TTSCacheDir          string `envconfig:"TTS_CACHE_DIR" default:"/var/cache/tts"`
	TTSVoice             string `envconfig:"TTS_VOICE" default:"tr-TR-Standard-A"`
	TTSWarmOnStart       bool   `envconfig:"TTS_WARM_ON_START" default:"true"`
	GeoRestrictCountries string `envconfig:"GEO_RESTRICT_COUNTRIES"`
	ResendAPIKey         string `envconfig:"RESEND_API_KEY"`
	ResendFrom           string `envconfig:"RESEND_FROM" default:"Marmaradar <noreply@marmaradar.com>"`
	ResendReplyTo        string `envconfig:"RESEND_REPLY_TO" default:"support@marmaradar.com"`
	EmailAppBaseURL      string `envconfig:"EMAIL_APP_BASE_URL" default:"https://marmaradar.com"`
}

// GoogleClientIDs returns configured Google OAuth audiences (Web/iOS/Android client IDs).
func (c Config) GoogleClientIDs() []string {
	return splitCSV(c.GoogleOAuthClientIDs)
}

// AppleClientIDs returns configured Apple OAuth audiences (bundle ID / Services ID).
func (c Config) AppleClientIDs() []string {
	return splitCSV(c.AppleOAuthClientIDs)
}

func splitCSV(s string) []string {
	parts := strings.Split(s, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p != "" {
			out = append(out, p)
		}
	}
	return out
}

func Load() Config {
	if strings.TrimSpace(os.Getenv("DATABASE_URL")) == "" {
		fmt.Fprintln(os.Stderr, "FATAL: DATABASE_URL environment variable is required")
		os.Exit(1)
	}

	var cfg Config
	if err := envconfig.Process("", &cfg); err != nil {
		fmt.Fprintf(os.Stderr, "FATAL: invalid configuration: %v\n", err)
		os.Exit(1)
	}

	if strings.TrimSpace(cfg.DatabaseURL) == "" {
		fmt.Fprintln(os.Stderr, "FATAL: DATABASE_URL environment variable is required")
		os.Exit(1)
	}

	if strings.TrimSpace(cfg.JWTSecret) == "" {
		cfg.JWTSecret = DevJWTSecret
	}

	return cfg
}
