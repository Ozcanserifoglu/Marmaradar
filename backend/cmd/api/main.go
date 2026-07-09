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
	"github.com/radar-alert/backend/internal/handler"
	"github.com/radar-alert/backend/internal/service"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)

	cfg := config.Load()
	ctx := context.Background()

	pool, err := db.NewPool(ctx, cfg.DatabaseURL)
	if err != nil {
		slog.Error("database connection failed", "error", err)
		os.Exit(1)
	}
	defer pool.Close()

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
