package config

import "github.com/kelseyhightower/envconfig"

type Config struct {
	DatabaseURL string `envconfig:"DATABASE_URL" required:"true"`
	Port        string `envconfig:"PORT" default:"8080"`
}

func Load() Config {
	var cfg Config
	envconfig.MustProcess("", &cfg)
	return cfg
}
