package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/radar-alert/backend/internal/auth"
	"github.com/radar-alert/backend/internal/client/distancematrix"
	"github.com/radar-alert/backend/internal/client/places"
	"github.com/radar-alert/backend/internal/client/roads"
	"github.com/radar-alert/backend/internal/config"
	"github.com/radar-alert/backend/internal/db"
	"github.com/radar-alert/backend/internal/db/migrate"
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

	jwtMgr := auth.NewJWTManager(cfg.JWTSecret, cfg.AccessTokenTTL, cfg.RefreshTokenTTL)
	geo := service.NewGeoService(pool)
	authSvc := service.NewAuthService(pool, jwtMgr)
	roadsClient := roads.NewClient(cfg.GoogleMapsAPIKey)
	if roadsClient.Enabled() {
		slog.Info("roads snap-to-road enabled")
	} else {
		slog.Info("roads snap-to-road disabled; set GOOGLE_MAPS_API_KEY to enable")
	}
	matrixClient := distancematrix.NewClient(cfg.GoogleMapsAPIKey)
	if matrixClient.Enabled() {
		slog.Info("distance matrix eta enabled")
	} else {
		slog.Info("distance matrix eta disabled; set GOOGLE_MAPS_API_KEY to enable")
	}
	placesClient := places.NewClient(cfg.GoogleMapsAPIKey)
	if placesClient.Enabled() {
		slog.Info("places amenities enabled")
	} else {
		slog.Info("places amenities disabled; set GOOGLE_MAPS_API_KEY to enable")
	}
	driveSvc := service.NewDriveService(pool, roadsClient)
	etaSvc := service.NewEtaService(pool, matrixClient)
	amenitiesSvc := service.NewAmenitiesService(placesClient)

	authHandler := handler.NewAuthHandler(authSvc)
	driveHandler := handler.NewDriveHandler(driveSvc)
	etaHandler := handler.NewEtaHandler(etaSvc)
	amenitiesHandler := handler.NewAmenitiesHandler(amenitiesSvc)

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

		r.Post("/auth/register", authHandler.Register)
		r.Post("/auth/login", authHandler.Login)
		r.Post("/auth/refresh", authHandler.Refresh)

		r.Group(func(r chi.Router) {
			r.Use(auth.Middleware(jwtMgr))
			r.Post("/drives", driveHandler.Create)
			r.Get("/drives", driveHandler.List)
			r.Get("/drives/{id}", driveHandler.Detail)
			r.Patch("/drives/{id}", driveHandler.Rename)
			r.Post("/eta/cameras", etaHandler.Cameras)
			r.Post("/amenities/cells", amenitiesHandler.Cells)
		})
	})

	slog.Info("starting api server", "port", cfg.Port)
	if err := http.ListenAndServe(":"+cfg.Port, r); err != nil {
		slog.Error("server stopped", "error", err)
		os.Exit(1)
	}
}
