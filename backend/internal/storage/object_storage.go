package storage

import (
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

// ObjectStorage abstracts blob persistence so local disk can be swapped for S3 later.
type ObjectStorage interface {
	Put(ctx context.Context, key string, r io.Reader, contentType string) error
	Open(ctx context.Context, key string) (io.ReadCloser, string, error)
	Delete(ctx context.Context, key string) error
}

// LocalObjectStorage stores objects under a root directory on disk.
type LocalObjectStorage struct {
	root string
}

func NewLocalObjectStorage(root string) (*LocalObjectStorage, error) {
	root = strings.TrimSpace(root)
	if root == "" {
		return nil, fmt.Errorf("upload root directory is required")
	}
	if err := os.MkdirAll(root, 0o755); err != nil {
		return nil, fmt.Errorf("create upload dir: %w", err)
	}
	return &LocalObjectStorage{root: root}, nil
}

func (s *LocalObjectStorage) Put(_ context.Context, key string, r io.Reader, contentType string) error {
	path, err := s.safePath(key)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}

	tmp := path + ".tmp"
	f, err := os.OpenFile(tmp, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o644)
	if err != nil {
		return err
	}
	if _, err := io.Copy(f, r); err != nil {
		_ = f.Close()
		_ = os.Remove(tmp)
		return err
	}
	if err := f.Close(); err != nil {
		_ = os.Remove(tmp)
		return err
	}
	if err := os.Rename(tmp, path); err != nil {
		_ = os.Remove(tmp)
		return err
	}

	metaPath := path + ".ctype"
	_ = os.WriteFile(metaPath, []byte(strings.TrimSpace(contentType)), 0o644)
	return nil
}

func (s *LocalObjectStorage) Open(_ context.Context, key string) (io.ReadCloser, string, error) {
	path, err := s.safePath(key)
	if err != nil {
		return nil, "", err
	}
	f, err := os.Open(path)
	if err != nil {
		return nil, "", err
	}
	contentType := "application/octet-stream"
	if b, err := os.ReadFile(path + ".ctype"); err == nil {
		if ct := strings.TrimSpace(string(b)); ct != "" {
			contentType = ct
		}
	}
	return f, contentType, nil
}

func (s *LocalObjectStorage) Delete(_ context.Context, key string) error {
	path, err := s.safePath(key)
	if err != nil {
		return err
	}
	_ = os.Remove(path + ".ctype")
	if err := os.Remove(path); err != nil && !os.IsNotExist(err) {
		return err
	}
	return nil
}

func (s *LocalObjectStorage) safePath(key string) (string, error) {
	key = strings.TrimSpace(strings.ReplaceAll(key, "\\", "/"))
	key = strings.TrimPrefix(key, "/")
	if key == "" || strings.Contains(key, "..") {
		return "", fmt.Errorf("invalid object key")
	}
	cleaned := filepath.Clean(key)
	full := filepath.Join(s.root, cleaned)
	rel, err := filepath.Rel(s.root, full)
	if err != nil || strings.HasPrefix(rel, "..") {
		return "", fmt.Errorf("invalid object key")
	}
	return full, nil
}
