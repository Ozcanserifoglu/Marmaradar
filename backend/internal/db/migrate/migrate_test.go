package migrate

import (
	"os"
	"path/filepath"
	"testing"
)

func TestMigrationFiles(t *testing.T) {
	dir := t.TempDir()
	for _, name := range []string{"002_b.sql", "001_a.sql", "ignore.txt"} {
		if err := os.WriteFile(filepath.Join(dir, name), []byte("-- test"), 0o644); err != nil {
			t.Fatal(err)
		}
	}

	files, err := migrationFiles(dir)
	if err != nil {
		t.Fatal(err)
	}
	if len(files) != 2 {
		t.Fatalf("got %d files, want 2", len(files))
	}
	if filepath.Base(files[0]) != "001_a.sql" {
		t.Fatalf("first file = %s, want 001_a.sql", files[0])
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
