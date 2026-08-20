package resend

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

const (
	sendURL        = "https://api.resend.com/emails"
	defaultTimeout = 10 * time.Second
	maxBody        = 1 << 20
)

type Client struct {
	apiKey     string
	endpoint   string
	httpClient *http.Client
}

func NewClient(apiKey string) *Client {
	return &Client{
		apiKey:   strings.TrimSpace(apiKey),
		endpoint: sendURL,
		httpClient: &http.Client{
			Timeout: defaultTimeout,
		},
	}
}

func (c *Client) Enabled() bool {
	return c != nil && c.apiKey != ""
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

type Message struct {
	From    string
	To      []string
	Subject string
	HTML    string
	Text    string
	ReplyTo string
}

type sendRequest struct {
	From    string   `json:"from"`
	To      []string `json:"to"`
	Subject string   `json:"subject"`
	HTML    string   `json:"html,omitempty"`
	Text    string   `json:"text,omitempty"`
	ReplyTo string   `json:"reply_to,omitempty"`
}

type errorResponse struct {
	StatusCode int    `json:"statusCode"`
	Name       string `json:"name"`
	Message    string `json:"message"`
}

func (c *Client) Send(ctx context.Context, msg Message) error {
	if !c.Enabled() {
		return fmt.Errorf("resend api key not configured")
	}
	to := trimNonEmpty(msg.To)
	if len(to) == 0 {
		return fmt.Errorf("resend to is empty")
	}
	from := strings.TrimSpace(msg.From)
	if from == "" {
		return fmt.Errorf("resend from is empty")
	}
	subject := strings.TrimSpace(msg.Subject)
	if subject == "" {
		return fmt.Errorf("resend subject is empty")
	}

	payload, err := json.Marshal(sendRequest{
		From:    from,
		To:      to,
		Subject: subject,
		HTML:    msg.HTML,
		Text:    msg.Text,
		ReplyTo: strings.TrimSpace(msg.ReplyTo),
	})
	if err != nil {
		return fmt.Errorf("encode resend request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.endpoint, bytes.NewReader(payload))
	if err != nil {
		return fmt.Errorf("build resend request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+c.apiKey)
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("resend request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, maxBody))
	if err != nil {
		return fmt.Errorf("read resend response: %w", err)
	}
	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		return nil
	}

	var parsed errorResponse
	if err := json.Unmarshal(body, &parsed); err == nil && parsed.Message != "" {
		return fmt.Errorf("resend http %d: %s", resp.StatusCode, parsed.Message)
	}
	msgBody := strings.TrimSpace(string(body))
	if msgBody == "" {
		msgBody = resp.Status
	}
	return fmt.Errorf("resend http %d: %s", resp.StatusCode, msgBody)
}

func trimNonEmpty(in []string) []string {
	out := make([]string, 0, len(in))
	for _, v := range in {
		v = strings.TrimSpace(v)
		if v != "" {
			out = append(out, v)
		}
	}
	return out
}
