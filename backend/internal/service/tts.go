package service

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"

	"github.com/radar-alert/backend/internal/client/tts"
)

var (
	ErrTTSUnavailable  = errors.New("tts unavailable")
	ErrTTSUnknownPhrase = errors.New("unknown phrase key")
	ErrTTSInvalidParams = errors.New("invalid tts params")
)

var distanceBuckets = []int{100, 200, 300, 500, 1000}

var phraseKeysWithDistance = []string{
	"camera.fixed",
	"camera.mobile",
	"camera.red_light",
	"camera.unknown",
	"report.police",
	"report.accident",
}

var staticPhraseKeys = []string{
	"corridor.warn",
	"corridor.over",
}

type SpeakRequest struct {
	PhraseKey string         `json:"phrase_key"`
	Params    map[string]any `json:"params"`
}

type SpeakResult struct {
	Audio   []byte
	CacheKey string
	CacheHit bool
	Text    string
}

type CatalogEntry struct {
	PhraseKey string `json:"phrase_key"`
	DistanceM *int   `json:"distance_m,omitempty"`
}

type TTSService struct {
	client   *tts.Client
	cacheDir string
	mu       sync.Mutex
}

func NewTTSService(client *tts.Client, cacheDir string) *TTSService {
	dir := strings.TrimSpace(cacheDir)
	if dir == "" {
		dir = "/var/cache/tts"
	}
	return &TTSService{
		client:   client,
		cacheDir: dir,
	}
}

func (s *TTSService) Enabled() bool {
	return s != nil && s.client != nil && s.client.Enabled()
}

func BucketDistance(distanceM float64) int {
	if distanceM <= 0 {
		return distanceBuckets[0]
	}
	for _, b := range distanceBuckets {
		if distanceM <= float64(b) {
			return b
		}
	}
	return distanceBuckets[len(distanceBuckets)-1]
}

func ResolvePhrase(phraseKey string, params map[string]any) (string, error) {
	key := strings.TrimSpace(phraseKey)
	switch key {
	case "camera.fixed", "camera.mobile", "camera.red_light", "camera.unknown",
		"report.police", "report.accident":
		dist, err := distanceParam(params)
		if err != nil {
			return "", err
		}
		return formatDistancePhrase(key, dist), nil
	case "corridor.warn":
		return "Hız limitine yaklaşıyorsunuz.", nil
	case "corridor.over":
		return "Hız limiti aşıldı.", nil
	default:
		return "", ErrTTSUnknownPhrase
	}
}

func distanceParam(params map[string]any) (int, error) {
	if params == nil {
		return 0, fmt.Errorf("%w: distance_m required", ErrTTSInvalidParams)
	}
	raw, ok := params["distance_m"]
	if !ok {
		return 0, fmt.Errorf("%w: distance_m required", ErrTTSInvalidParams)
	}
	var dist int
	switch v := raw.(type) {
	case float64:
		dist = int(v)
	case int:
		dist = v
	case int64:
		dist = int(v)
	case string:
		parsed, err := strconv.Atoi(strings.TrimSpace(v))
		if err != nil {
			return 0, fmt.Errorf("%w: distance_m invalid", ErrTTSInvalidParams)
		}
		dist = parsed
	default:
		return 0, fmt.Errorf("%w: distance_m invalid", ErrTTSInvalidParams)
	}
	for _, b := range distanceBuckets {
		if dist == b {
			return dist, nil
		}
	}
	return 0, fmt.Errorf("%w: distance_m must be one of %v", ErrTTSInvalidParams, distanceBuckets)
}

func formatDistancePhrase(key string, distanceM int) string {
	switch key {
	case "camera.fixed":
		return fmt.Sprintf("Dikkat, sabit hız kamerası, %d metre ileride.", distanceM)
	case "camera.mobile":
		return fmt.Sprintf("Dikkat, mobil radar, %d metre ileride.", distanceM)
	case "camera.red_light":
		return fmt.Sprintf("Dikkat, kırmızı ışık kamerası, %d metre ileride.", distanceM)
	case "camera.unknown":
		return fmt.Sprintf("Dikkat, hız kamerası, %d metre ileride.", distanceM)
	case "report.police":
		return fmt.Sprintf("Dikkat, polis kontrolü, %d metre ileride.", distanceM)
	case "report.accident":
		return fmt.Sprintf("Dikkat, kaza, %d metre ileride.", distanceM)
	default:
		return ""
	}
}

func (s *TTSService) Catalog() []CatalogEntry {
	out := make([]CatalogEntry, 0, len(phraseKeysWithDistance)*len(distanceBuckets)+len(staticPhraseKeys))
	for _, key := range phraseKeysWithDistance {
		for _, d := range distanceBuckets {
			dist := d
			out = append(out, CatalogEntry{PhraseKey: key, DistanceM: &dist})
		}
	}
	for _, key := range staticPhraseKeys {
		out = append(out, CatalogEntry{PhraseKey: key})
	}
	return out
}

func (s *TTSService) cacheKey(text string) string {
	voice := ""
	lang := ""
	if s.client != nil {
		voice = s.client.Voice()
		lang = s.client.Language()
	}
	sum := sha256.Sum256([]byte(voice + "|" + lang + "|" + text))
	return hex.EncodeToString(sum[:])
}

func (s *TTSService) Speak(ctx context.Context, req SpeakRequest) (*SpeakResult, error) {
	if !s.Enabled() {
		return nil, ErrTTSUnavailable
	}

	text, err := ResolvePhrase(req.PhraseKey, req.Params)
	if err != nil {
		return nil, err
	}

	key := s.cacheKey(text)
	path := filepath.Join(s.cacheDir, key+".mp3")

	if data, err := os.ReadFile(path); err == nil && len(data) > 0 {
		return &SpeakResult{
			Audio:    data,
			CacheKey: key,
			CacheHit: true,
			Text:     text,
		}, nil
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	// Re-check after lock in case another request filled the cache.
	if data, err := os.ReadFile(path); err == nil && len(data) > 0 {
		return &SpeakResult{
			Audio:    data,
			CacheKey: key,
			CacheHit: true,
			Text:     text,
		}, nil
	}

	audio, err := s.client.Synthesize(ctx, text)
	if err != nil {
		return nil, fmt.Errorf("synthesize: %w", err)
	}

	if err := s.writeCache(path, audio); err != nil {
		slog.Warn("tts cache write failed", "error", err, "path", path)
	}

	return &SpeakResult{
		Audio:    audio,
		CacheKey: key,
		CacheHit: false,
		Text:     text,
	}, nil
}

func (s *TTSService) writeCache(path string, audio []byte) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, audio, 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}

// WarmCatalog synthesizes every catalog entry. Best-effort; logs failures.
func (s *TTSService) WarmCatalog(ctx context.Context) (warmed int, err error) {
	if !s.Enabled() {
		return 0, ErrTTSUnavailable
	}
	var firstErr error
	for _, entry := range s.Catalog() {
		params := map[string]any{}
		if entry.DistanceM != nil {
			params["distance_m"] = *entry.DistanceM
		}
		res, speakErr := s.Speak(ctx, SpeakRequest{
			PhraseKey: entry.PhraseKey,
			Params:    params,
		})
		if speakErr != nil {
			if firstErr == nil {
				firstErr = speakErr
			}
			slog.Warn("tts warm failed", "phrase_key", entry.PhraseKey, "error", speakErr)
			continue
		}
		if !res.CacheHit {
			warmed++
		}
	}
	return warmed, firstErr
}
