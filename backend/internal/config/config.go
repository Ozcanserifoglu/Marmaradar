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
	GoogleMapsAPIKey     string `envconfig:"GOOGLE_MAPS_API_KEY"`
	GeoRestrictCountries string `envconfig:"GEO_RESTRICT_COUNTRIES"`
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
