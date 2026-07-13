package migrate

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
)

const schemaDDL = `
CREATE TABLE IF NOT EXISTS schema_migrations (
    version    TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
);`

// Run applies pending SQL migrations from dir in lexicographic order.
// Each file is recorded in schema_migrations after a successful run..
func Run(ctx context.Context, pool *pgxpool.Pool, dir string) error {
	if _, err := os.Stat(dir); err != nil {
		return fmt.Errorf("migrations directory %q: %w", dir, err)
	}

	if _, err := pool.Exec(ctx, schemaDDL); err != nil {
		return fmt.Errorf("create schema_migrations: %w", err)
	}

	if err := bootstrapFromExistingSchema(ctx, pool, dir); err != nil {
		return err
	}

	files, err := migrationFiles(dir)
	if err != nil {
		return err
	}

	applied, err := appliedVersions(ctx, pool)
	if err != nil {
		return err
	}

	for _, file := range files {
		version := strings.TrimSuffix(filepath.Base(file), filepath.Ext(file))
		if applied[version] {
			slog.Info("migration already applied", "version", version)
			continue
		}

		sql, err := os.ReadFile(file)
		if err != nil {
			return fmt.Errorf("read migration %s: %w", file, err)
		}

		slog.Info("applying migration", "version", version, "file", file)
		if err := applyMigration(ctx, pool, version, string(sql)); err != nil {
			return fmt.Errorf("apply migration %s: %w", version, err)
		}
	}

	return nil
}

// bootstrapFromExistingSchema marks migrations as applied when the database was
// initialized externally (e.g. docker-entrypoint-initdb.d) so API startup does
// not attempt to re-run them.
func bootstrapFromExistingSchema(ctx context.Context, pool *pgxpool.Pool, dir string) error {
	var regionsExists bool
	err := pool.QueryRow(ctx, `
		SELECT EXISTS (
			SELECT 1 FROM information_schema.tables
			WHERE table_schema = 'public' AND table_name = 'regions'
		)`).Scan(&regionsExists)
	if err != nil {
		return fmt.Errorf("check existing schema: %w", err)
	}
	if !regionsExists {
		return nil
	}

	var count int
	if err := pool.QueryRow(ctx, `SELECT COUNT(*) FROM schema_migrations`).Scan(&count); err != nil {
		return fmt.Errorf("count schema_migrations: %w", err)
	}
	if count > 0 {
		return nil
	}

	files, err := migrationFiles(dir)
	if err != nil {
		return err
	}

	slog.Info("bootstrapping schema_migrations from existing database schema", "count", len(files))
	for _, file := range files {
		version := strings.TrimSuffix(filepath.Base(file), filepath.Ext(file))
		if _, err := pool.Exec(ctx, `INSERT INTO schema_migrations (version) VALUES ($1) ON CONFLICT DO NOTHING`, version); err != nil {
			return fmt.Errorf("bootstrap migration %s: %w", version, err)
		}
	}
	return nil
}

func migrationFiles(dir string) ([]string, error) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, fmt.Errorf("read migrations dir: %w", err)
	}

	var files []string
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".sql") {
			continue
		}
		files = append(files, filepath.Join(dir, e.Name()))
	}
	sort.Strings(files)
	if len(files) == 0 {
		return nil, fmt.Errorf("no .sql migrations found in %q", dir)
	}
	return files, nil
}

func appliedVersions(ctx context.Context, pool *pgxpool.Pool) (map[string]bool, error) {
	rows, err := pool.Query(ctx, `SELECT version FROM schema_migrations`)
	if err != nil {
		return nil, fmt.Errorf("list applied migrations: %w", err)
	}
	defer rows.Close()

	applied := make(map[string]bool)
	for rows.Next() {
		var version string
		if err := rows.Scan(&version); err != nil {
			return nil, err
		}
		applied[version] = true
	}
	return applied, rows.Err()
}

func applyMigration(ctx context.Context, pool *pgxpool.Pool, version, sql string) error {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, sql); err != nil {
		return err
	}
	if _, err := tx.Exec(ctx, `INSERT INTO schema_migrations (version) VALUES ($1)`, version); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

// ResolveDir returns the migrations directory from MIGRATIONS_DIR or common
// monorepo-relative paths for local development.
func ResolveDir() (string, error) {
	if dir := os.Getenv("MIGRATIONS_DIR"); dir != "" {
		return dir, nil
	}

	candidates := []string{
		"migrations",
		"backend/migrations",
		"infra/migrations",
		"../migrations",
		"../infra/migrations",
		"../../infra/migrations",
		filepath.Join("..", "..", "infra", "migrations"),
	}
	for _, c := range candidates {
		if st, err := os.Stat(c); err == nil && st.IsDir() {
			abs, err := filepath.Abs(c)
			if err != nil {
				return c, nil
			}
			return abs, nil
		}
	}
	return "", fmt.Errorf("migrations directory not found; set MIGRATIONS_DIR (e.g. /migrations in production)")
}

// Ping verifies the database is reachable before migrations run.
func Ping(ctx context.Context, pool *pgxpool.Pool) error {
	return pool.Ping(ctx)
}
