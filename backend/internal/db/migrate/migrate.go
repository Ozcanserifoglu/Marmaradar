package migrate

import (
	"context"
	"errors"
	"fmt"
	"io/fs"
	"log/slog"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/radar-alert/backend/migrations"
)

const (
	schemaDDL = `
CREATE TABLE IF NOT EXISTS schema_migrations (
    version    TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
);`
	// Arbitrary lock key so multiple API replicas do not apply the same file.
	advisoryLockKey int64 = 74610013
)

type Result struct {
	Source  string
	Applied []string
	Skipped []string
}

func (r Result) UpToDate() bool {
	return len(r.Applied) == 0
}

func Run(ctx context.Context, pool *pgxpool.Pool, dir string) error {
	_, err := RunFS(ctx, pool, dir)
	return err
}

func RunFS(ctx context.Context, pool *pgxpool.Pool, dir string) (*Result, error) {
	src, label, err := resolveSource(dir)
	if err != nil {
		return nil, err
	}

	conn, err := pool.Acquire(ctx)
	if err != nil {
		return nil, fmt.Errorf("acquire migration connection: %w", err)
	}
	defer conn.Release()

	if _, err := conn.Exec(ctx, `SELECT pg_advisory_lock($1)`, advisoryLockKey); err != nil {
		return nil, fmt.Errorf("acquire migration lock: %w", err)
	}
	defer func() {
		if _, unlockErr := conn.Exec(context.Background(), `SELECT pg_advisory_unlock($1)`, advisoryLockKey); unlockErr != nil {
			slog.Warn("release migration lock failed", "error", unlockErr)
		}
	}()

	if _, err := conn.Exec(ctx, schemaDDL); err != nil {
		return nil, fmt.Errorf("create schema_migrations: %w", err)
	}

	files, err := listSQL(src)
	if err != nil {
		return nil, err
	}

	applied, err := appliedVersions(ctx, conn)
	if err != nil {
		return nil, err
	}

	result := &Result{Source: label}
	for _, name := range files {
		version := strings.TrimSuffix(name, filepath.Ext(name))
		if applied[version] {
			result.Skipped = append(result.Skipped, version)
			slog.Info("migration already applied", "version", version)
			continue
		}

		sqlBytes, err := fs.ReadFile(src, name)
		if err != nil {
			return nil, fmt.Errorf("read migration %s: %w", name, err)
		}

		slog.Info("applying migration", "version", version, "source", label)
		recorded, err := applyMigration(ctx, conn, version, string(sqlBytes))
		if err != nil {
			slog.Error("migration failed", "version", version, "error", err)
			return nil, fmt.Errorf("apply migration %s: %w", version, err)
		}
		if recorded == "duplicate" {
			result.Skipped = append(result.Skipped, version)
			slog.Warn("migration objects already exist; recorded as applied", "version", version)
			continue
		}
		result.Applied = append(result.Applied, version)
		slog.Info("migration applied", "version", version)
	}

	if result.UpToDate() {
		slog.Info("database schema is up to date", "source", label, "migrations", len(files))
	} else {
		slog.Info("database migrations complete",
			"source", label,
			"applied", len(result.Applied),
			"skipped", len(result.Skipped),
			"versions", result.Applied,
		)
	}
	return result, nil
}

func resolveSource(dir string) (fs.FS, string, error) {
	if dir == "" {
		dir = os.Getenv("MIGRATIONS_DIR")
	}
	if dir != "" {
		if hasSQL(dir) {
			return os.DirFS(dir), dir, nil
		}
		slog.Warn("MIGRATIONS_DIR is set but has no .sql files; using embedded migrations", "dir", dir)
	}
	names, err := fs.Glob(migrations.FS, "*.sql")
	if err != nil || len(names) == 0 {
		return nil, "", fmt.Errorf("no embedded .sql migrations found")
	}
	return migrations.FS, "embed", nil
}

func hasSQL(dir string) bool {
	matches, err := filepath.Glob(filepath.Join(dir, "*.sql"))
	return err == nil && len(matches) > 0
}

func listSQL(src fs.FS) ([]string, error) {
	entries, err := fs.ReadDir(src, ".")
	if err != nil {
		return nil, fmt.Errorf("read migrations: %w", err)
	}
	var files []string
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".sql") {
			continue
		}
		files = append(files, e.Name())
	}
	sort.Strings(files)
	if len(files) == 0 {
		return nil, fmt.Errorf("no .sql migrations found")
	}
	return files, nil
}

type sessionConn interface {
	Exec(ctx context.Context, sql string, arguments ...any) (pgconn.CommandTag, error)
	Query(ctx context.Context, sql string, arguments ...any) (pgx.Rows, error)
	Begin(ctx context.Context) (pgx.Tx, error)
}

func appliedVersions(ctx context.Context, conn sessionConn) (map[string]bool, error) {
	rows, err := conn.Query(ctx, `SELECT version FROM schema_migrations`)
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

func applyMigration(ctx context.Context, conn sessionConn, version, sql string) (string, error) {
	tx, err := conn.Begin(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, sql); err != nil {
		if isAlreadyPresent(err) {
			if err := tx.Rollback(ctx); err != nil && !errors.Is(err, context.Canceled) {
				slog.Warn("rollback after duplicate migration", "error", err)
			}
			if _, err := conn.Exec(ctx, `INSERT INTO schema_migrations (version) VALUES ($1) ON CONFLICT DO NOTHING`, version); err != nil {
				return "", err
			}
			return "duplicate", nil
		}
		return "", err
	}
	if _, err := tx.Exec(ctx, `INSERT INTO schema_migrations (version) VALUES ($1)`, version); err != nil {
		return "", err
	}
	if err := tx.Commit(ctx); err != nil {
		return "", err
	}
	return "applied", nil
}

func isAlreadyPresent(err error) bool {
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) {
		return false
	}
	switch pgErr.Code {
	case "42P07", // duplicate_table
		"42710", // duplicate_object
		"42701", // duplicate_column
		"42P16": // invalid_table_definition overlapping
		return true
	default:
		return false
	}
}

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
	return "", fmt.Errorf("migrations directory not found; embedded SQL will be used")
}

func Ping(ctx context.Context, pool *pgxpool.Pool) error {
	return pool.Ping(ctx)
}
