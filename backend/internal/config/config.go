package config

import (
	"fmt"
	"os"
	"strings"

	"github.com/kelseyhightower/envconfig"
)

type Config struct {
	DatabaseURL      string `envconfig:"DATABASE_URL" required:"true"`
	Port             string `envconfig:"PORT" default:"8080"`
	MigrationsDir    string `envconfig:"MIGRATIONS_DIR"`
	JWTSecret        string `envconfig:"JWT_SECRET" default:"dev-only-change-me-in-production"`
	AccessTokenTTL   int    `envconfig:"ACCESS_TOKEN_TTL" default:"900"`     // seconds
	RefreshTokenTTL  int    `envconfig:"REFRESH_TOKEN_TTL" default:"2592000"` // seconds (30d)
	GoogleMapsAPIKey string `envconfig:"GOOGLE_MAPS_API_KEY"`                 // optional; enables Roads snap-to-road
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

	return cfg
}
