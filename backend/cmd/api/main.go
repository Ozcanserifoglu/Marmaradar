package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/radar-alert/backend/internal/config"
	"github.com/radar-alert/backend/internal/db"
	"github.com/radar-alert/backend/internal/db/migrate"
	"github.com/radar-alert/backend/internal/handler"
	"github.com/radar-alert/backend/internal/service"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)

	// API server only — data seeding runs via data-pipeline/cmd/importer (separate CLI).
	cfg := config.Load()
	ctx := context.Background()

	pool, err := db.NewPool(ctx, cfg.DatabaseURL)
	if err != nil {
		slog.Error("database connection failed", "error", err)
		os.Exit(1)
	}
	defer pool.Close()

	if err := migrate.Ping(ctx, pool); err != nil {
		slog.Error("database ping failed", "error", err)
		os.Exit(1)
	}

	migrationsDir := cfg.MigrationsDir
	if migrationsDir == "" {
		migrationsDir, err = migrate.ResolveDir()
		if err != nil {
			slog.Error("migrations directory not found", "error", err)
			os.Exit(1)
		}
	}

	slog.Info("running database migrations", "dir", migrationsDir)
	if err := migrate.Run(ctx, pool, migrationsDir); err != nil {
		slog.Error("database migration failed", "error", err)
		os.Exit(1)
	}
	slog.Info("database migrations complete")

	geo := service.NewGeoService(pool)

	r := chi.NewRouter()
	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	r.Get("/health", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"status":"ok"}`))
	})

	r.Route("/v1", func(r chi.Router) {
		r.Get("/cameras/nearby", handler.NewCameraHandler(geo).Nearby)
		r.Get("/corridors/nearby", handler.NewCorridorHandler(geo).Nearby)
		r.Get("/sync", handler.NewSyncHandler(geo).Delta)
	})

	slog.Info("starting api server", "port", cfg.Port)
	if err := http.ListenAndServe(":"+cfg.Port, r); err != nil {
		slog.Error("server stopped", "error", err)
		os.Exit(1)
	}
}
