// @title           Marmaradar API
// @version         1.0
// @description     ## Welcome
// @description     Marmaradar helps drivers in Turkey stay aware of speed cameras, average-speed corridors, and community road reports. This reference documents the REST API used by the mobile app and future integrations.
// @description
// @description     ## Base URL
// @description     **This site (`api.marmaradar.com`) hosts documentation only.** To call the API, send requests to the Marmaradar **gateway**:
// @description
// @description     | Environment | Base URL |
// @description     |-------------|----------|
// @description     | Production gateway | `http://35.239.129.237:8081` |
// @description     | Local development | `http://127.0.0.1:8081` |
// @description
// @description     All paths below are relative to that gateway base (e.g. `GET /v1/users/me` → `http://35.239.129.237:8081/v1/users/me`).
// @description
// @description     ## Authentication
// @description     Most endpoints require a JWT **access token** obtained via `/v1/auth/login`, `/v1/auth/register`, or `/v1/auth/oauth`. Pass it on every protected request:
// @description
// @description     ```
// @description     Authorization: Bearer <access_token>
// @description     ```
// @description
// @description     When the access token expires, refresh it with `POST /v1/auth/refresh` and the `refresh_token` from the login response.
// @description
// @description     ## Conventions
// @description     - Request and response bodies are JSON unless noted (e.g. profile photo upload uses `multipart/form-data`).
// @description     - Errors return `{"error": "<human-readable message>"}` with an appropriate HTTP status code.
// @description     - UUIDs are lowercase strings (e.g. `550e8400-e29b-41d4-a716-446655440000`).
// @termsOfService  https://www.marmaradar.com/terms
//
// @contact.name   Marmaradar Support
// @contact.url    https://www.marmaradar.com
//
// @license.name   Proprietary
//
// @host      35.239.129.237:8081
// @BasePath  /
// @schemes   http
//
// @securityDefinitions.apikey BearerAuth
// @in                         header
// @name                       Authorization
// @description                Short-lived JWT from login/register/oauth. Example: `Bearer eyJhbGciOiJIUzI1NiIs...`
//
// @tag.name        Account & Profile
// @tag.description Read the signed-in user's account details and saved preferences.
//
// @tag.name        Vehicle Customization
// @tag.description Choose the vehicle icon shown on the live map and in exported drive videos.
//
// @tag.name        Profile Photo
// @tag.description Upload and retrieve the user's avatar image.
package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/radar-alert/backend/internal/apidocs"
	"github.com/radar-alert/backend/internal/auth"
	"github.com/radar-alert/backend/internal/client/distancematrix"
	"github.com/radar-alert/backend/internal/client/places"
	"github.com/radar-alert/backend/internal/client/resend"
	"github.com/radar-alert/backend/internal/client/roads"
	"github.com/radar-alert/backend/internal/client/tts"
	"github.com/radar-alert/backend/internal/config"
	"github.com/radar-alert/backend/internal/db"
	"github.com/radar-alert/backend/internal/db/migrate"
	"github.com/radar-alert/backend/internal/email"
	"github.com/radar-alert/backend/internal/georestrict"
	"github.com/radar-alert/backend/internal/handler"
	"github.com/radar-alert/backend/internal/service"
	"github.com/radar-alert/backend/internal/storage"

	_ "github.com/radar-alert/backend/docs"
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
	slog.Info("running database migrations before serving traffic")
	result, err := migrate.RunFS(ctx, pool, migrationsDir)
	if err != nil {
		slog.Error("database migration failed; refusing to start HTTP server", "error", err)
		os.Exit(1)
	}
	if result.UpToDate() {
		slog.Info("database already up to date", "source", result.Source)
	}

	if cfg.JWTSecret == config.DevJWTSecret {
		slog.Warn("JWT_SECRET is unset, falling back to the public dev secret; anyone can forge tokens against this instance")
	}

	jwtMgr := auth.NewJWTManager(cfg.JWTSecret, cfg.AccessTokenTTL, cfg.RefreshTokenTTL)
	geo := service.NewGeoService(pool)
	resendClient := resend.NewClient(cfg.ResendAPIKey)
	mailer := email.NewMailer(resendClient, cfg.ResendFrom, cfg.ResendReplyTo)
	if mailer.Enabled() {
		slog.Info("resend email enabled", "from", cfg.ResendFrom)
	} else {
		slog.Info("resend email disabled; set RESEND_API_KEY to enable")
	}
	authSvc := service.NewAuthService(pool, jwtMgr, cfg.GoogleClientIDs(), cfg.AppleClientIDs(), mailer, cfg.EmailAppBaseURL)
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
	ttsAPIKey := cfg.GoogleTTSAPIKey
	if ttsAPIKey == "" {
		ttsAPIKey = cfg.GoogleMapsAPIKey
	}
	ttsClient := tts.NewClient(ttsAPIKey, cfg.TTSVoice)
	ttsSvc := service.NewTTSService(ttsClient, cfg.TTSCacheDir)
	if ttsSvc.Enabled() {
		slog.Info("tts voice alerts enabled", "voice", cfg.TTSVoice, "cache_dir", cfg.TTSCacheDir)
	} else {
		slog.Info("tts voice alerts disabled; set GOOGLE_TTS_API_KEY or GOOGLE_MAPS_API_KEY to enable")
	}
	driveSvc := service.NewDriveService(pool, roadsClient)
	statsSvc := service.NewStatsService(pool)
	leaderboardSvc := service.NewLeaderboardService(pool)
	reportSvc := service.NewReportService(pool)
	liveReportSvc := service.NewLiveReportService(pool)
	etaSvc := service.NewEtaService(pool, matrixClient)
	amenitiesSvc := service.NewAmenitiesService(placesClient)
	uploadStore, err := storage.NewLocalObjectStorage(cfg.UploadDir)
	if err != nil {
		slog.Error("upload storage init failed", "error", err, "upload_dir", cfg.UploadDir)
		os.Exit(1)
	}
	usersSvc := service.NewUsersService(pool, uploadStore)
	slog.Info("profile uploads enabled", "upload_dir", cfg.UploadDir)

	authHandler := handler.NewAuthHandler(authSvc)
	driveHandler := handler.NewDriveHandler(driveSvc)
	statsHandler := handler.NewStatsHandler(statsSvc)
	leaderboardHandler := handler.NewLeaderboardHandler(leaderboardSvc)
	usersHandler := handler.NewUsersHandler(usersSvc)
	reportHandler := handler.NewReportHandler(reportSvc)
	liveReportHandler := handler.NewLiveReportHandler(liveReportSvc)
	etaHandler := handler.NewEtaHandler(etaSvc)
	amenitiesHandler := handler.NewAmenitiesHandler(amenitiesSvc)
	ttsHandler := handler.NewTTSHandler(ttsSvc)

	// Soft-expire stale crowd reports in the background.
	go func() {
		ticker := time.NewTicker(time.Minute)
		defer ticker.Stop()
		for {
			if _, err := reportSvc.ExpireStale(context.Background()); err != nil {
				slog.Warn("expire mobile cameras failed", "error", err)
			}
			<-ticker.C
		}
	}()

	// Settle live reports when they expire or hit score thresholds.
	go func() {
		ticker := time.NewTicker(30 * time.Second)
		defer ticker.Stop()
		for {
			if _, err := liveReportSvc.SettleExpired(context.Background()); err != nil {
				slog.Warn("settle live reports failed", "error", err)
			}
			<-ticker.C
		}
	}()

	// Reconcile verified contribution counters against source tables.
	go func() {
		ticker := time.NewTicker(5 * time.Minute)
		defer ticker.Stop()
		for {
			n, err := statsSvc.ReconcileValidContributions(context.Background())
			if err != nil {
				slog.Warn("reconcile valid_contributions failed", "error", err)
			} else if n > 0 {
				slog.Info("reconciled valid_contributions", "rows", n)
			}
			<-ticker.C
		}
	}()

	if cfg.TTSWarmOnStart && ttsSvc.Enabled() {
		go func() {
			ctx, cancel := context.WithTimeout(context.Background(), 3*time.Minute)
			defer cancel()
			warmed, err := ttsSvc.WarmCatalog(ctx)
			if err != nil {
				slog.Warn("tts catalog warm incomplete", "warmed", warmed, "error", err)
				return
			}
			slog.Info("tts catalog warm complete", "synthesized", warmed)
		}()
	}

	geoGuard, err := georestrict.New(georestrict.ParseCountries(cfg.GeoRestrictCountries))
	if err != nil {
		slog.Error("geo restriction config failed", "error", err)
		os.Exit(1)
	}
	if geoGuard != nil {
		slog.Info("geo restriction enabled", "countries", cfg.GeoRestrictCountries)
	}

	r := chi.NewRouter()
	r.Use(middleware.RequestID)
	r.Use(geoGuard.Middleware)
	r.Use(middleware.RealIP)
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	r.Get("/health", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"status":"ok"}`))
	})

	docsHandler := apidocs.NewHandler()
	r.Get("/", docsHandler.ServeUI)
	r.Get("/docs", docsHandler.ServeUI)
	r.Get("/docs/", docsHandler.ServeUI)
	r.Get("/openapi.json", docsHandler.ServeSpec)

	r.Get("/reset-password", authHandler.ResetPasswordPage)

	r.Route("/v1", func(r chi.Router) {
		r.Get("/cameras/nearby", handler.NewCameraHandler(geo).Nearby)
		r.Get("/corridors/nearby", handler.NewCorridorHandler(geo).Nearby)
		r.Get("/sync", handler.NewSyncHandler(geo).Delta)
		r.Get("/live-reports/active", liveReportHandler.Active)
		r.Get("/uploads/*", usersHandler.ServeUpload)

		r.Post("/auth/register", authHandler.Register)
		r.Post("/auth/login", authHandler.Login)
		r.Post("/auth/refresh", authHandler.Refresh)
		r.Post("/auth/oauth", authHandler.OAuth)
		r.Post("/auth/forgot-password", authHandler.ForgotPassword)
		r.Post("/auth/reset-password", authHandler.ResetPassword)

		r.Group(func(r chi.Router) {
			r.Use(auth.Middleware(jwtMgr))
			r.Post("/drives", driveHandler.Create)
			r.Get("/drives", driveHandler.List)
			r.Get("/drives/{id}", driveHandler.Detail)
			r.Patch("/drives/{id}", driveHandler.Rename)
			r.Get("/users/me", usersHandler.Me)
			r.Patch("/users/me", usersHandler.UpdateMe)
			r.Post("/users/me/profile-picture", usersHandler.UploadProfilePicture)
			r.Get("/users/me/stats", statsHandler.Me)
			r.Get("/leaderboard", leaderboardHandler.Get)
			r.Post("/reports", reportHandler.Create)
			r.Post("/reports/{id}/votes", reportHandler.Vote)
			r.Post("/live-reports", liveReportHandler.Create)
			r.Post("/live-reports/{id}/vote", liveReportHandler.Vote)
			r.Post("/eta/cameras", etaHandler.Cameras)
			r.Post("/amenities/cells", amenitiesHandler.Cells)
			r.Post("/tts/speak", ttsHandler.Speak)
			r.Get("/tts/catalog", ttsHandler.Catalog)
		})
	})

	slog.Info("starting api server", "port", cfg.Port)
	if err := http.ListenAndServe(":"+cfg.Port, r); err != nil {
		slog.Error("server stopped", "error", err)
		os.Exit(1)
	}
}
