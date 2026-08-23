package migrate

import (
	"io/fs"
	"os"
	"path/filepath"
	"testing"

	"github.com/radar-alert/backend/migrations"
)

func TestListSQLSorted(t *testing.T) {
	dir := t.TempDir()
	for _, name := range []string{"002_b.sql", "001_a.sql", "ignore.txt"} {
		if err := os.WriteFile(filepath.Join(dir, name), []byte("-- test"), 0o644); err != nil {
			t.Fatal(err)
		}
	}

	files, err := listSQL(os.DirFS(dir))
	if err != nil {
		t.Fatal(err)
	}
	if len(files) != 2 {
		t.Fatalf("got %d files, want 2", len(files))
	}
	if files[0] != "001_a.sql" {
		t.Fatalf("first file = %s, want 001_a.sql", files[0])
	}
}

func TestEmbeddedMigrationsPresent(t *testing.T) {
	names, err := fs.Glob(migrations.FS, "*.sql")
	if err != nil {
		t.Fatal(err)
	}
	if len(names) < 13 {
		t.Fatalf("embedded %d sql files, want at least 13", len(names))
	}
	found := false
	for _, n := range names {
		if n == "013_drive_speed_stats.sql" {
			found = true
			break
		}
	}
	if !found {
		t.Fatal("013_drive_speed_stats.sql is not embedded")
	}
}

func TestResolveDirFromEnv(t *testing.T) {
	dir := t.TempDir()
	t.Setenv("MIGRATIONS_DIR", dir)

	got, err := ResolveDir()
	if err != nil {
		t.Fatal(err)
	}
	if got != dir {
		t.Fatalf("ResolveDir() = %q, want %q", got, dir)
	}
}

func TestResolveSourceFallsBackToEmbed(t *testing.T) {
	src, label, err := resolveSource(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	if label != "embed" {
		t.Fatalf("source = %q, want embed", label)
	}
	files, err := listSQL(src)
	if err != nil {
		t.Fatal(err)
	}
	if len(files) == 0 {
		t.Fatal("embedded source is empty")
	}
}
