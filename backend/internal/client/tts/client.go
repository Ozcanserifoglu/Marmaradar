package tts

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

const (
	synthesizeURL  = "https://texttospeech.googleapis.com/v1/text:synthesize"
	defaultTimeout = 12 * time.Second
)

type Client struct {
	apiKey     string
	voice      string
	language   string
	endpoint   string
	httpClient *http.Client
}

func NewClient(apiKey, voice string) *Client {
	v := strings.TrimSpace(voice)
	if v == "" {
		v = "tr-TR-Standard-A"
	}
	return &Client{
		apiKey:   strings.TrimSpace(apiKey),
		voice:    v,
		language: "tr-TR",
		endpoint: synthesizeURL,
		httpClient: &http.Client{
			Timeout: defaultTimeout,
		},
	}
}

func (c *Client) Enabled() bool {
	return c != nil && c.apiKey != ""
}

func (c *Client) Voice() string {
	if c == nil {
		return ""
	}
	return c.voice
}

func (c *Client) Language() string {
	if c == nil {
		return ""
	}
	return c.language
}

func (c *Client) SetHTTPForTest(endpoint string, httpClient *http.Client) {
	if c == nil {
		return
	}
	c.endpoint = endpoint
	if httpClient != nil {
		c.httpClient = httpClient
	}
}

type synthesizeRequest struct {
	Input       synthesizeInput `json:"input"`
	Voice       voiceSelect     `json:"voice"`
	AudioConfig audioConfig     `json:"audioConfig"`
}

type synthesizeInput struct {
	Text string `json:"text"`
}

type voiceSelect struct {
	LanguageCode string `json:"languageCode"`
	Name         string `json:"name"`
}

type audioConfig struct {
	AudioEncoding string `json:"audioEncoding"`
}

type synthesizeResponse struct {
	AudioContent string `json:"audioContent"`
	Error        *struct {
		Code    int    `json:"code"`
		Message string `json:"message"`
		Status  string `json:"status"`
	} `json:"error"`
}

// Synthesize returns MP3 audio bytes for the given Turkish text.
func (c *Client) Synthesize(ctx context.Context, text string) ([]byte, error) {
	if !c.Enabled() {
		return nil, fmt.Errorf("tts api key not configured")
	}
	text = strings.TrimSpace(text)
	if text == "" {
		return nil, fmt.Errorf("tts text is empty")
	}

	payload, err := json.Marshal(synthesizeRequest{
		Input: synthesizeInput{Text: text},
		Voice: voiceSelect{
			LanguageCode: c.language,
			Name:         c.voice,
		},
		AudioConfig: audioConfig{AudioEncoding: "MP3"},
	})
	if err != nil {
		return nil, fmt.Errorf("encode tts request: %w", err)
	}

	endpoint := c.endpoint
	if strings.Contains(endpoint, "googleapis.com") {
		q := url.Values{}
		q.Set("key", c.apiKey)
		endpoint = endpoint + "?" + q.Encode()
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(payload))
	if err != nil {
		return nil, fmt.Errorf("build tts request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("tts request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 4<<20))
	if err != nil {
		return nil, fmt.Errorf("read tts response: %w", err)
	}

	var parsed synthesizeResponse
	if err := json.Unmarshal(body, &parsed); err != nil {
		return nil, fmt.Errorf("decode tts response: %w", err)
	}
	if parsed.Error != nil {
		return nil, fmt.Errorf("tts api error %s: %s", parsed.Error.Status, parsed.Error.Message)
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("tts http %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}
	if parsed.AudioContent == "" {
		return nil, fmt.Errorf("tts response missing audioContent")
	}

	audio, err := base64.StdEncoding.DecodeString(parsed.AudioContent)
	if err != nil {
		return nil, fmt.Errorf("decode tts audio: %w", err)
	}
	if len(audio) == 0 {
		return nil, fmt.Errorf("tts audio is empty")
	}
	return audio, nil
}
