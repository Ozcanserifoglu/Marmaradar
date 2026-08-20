package email

import (
	"context"
	"log/slog"
	"strings"
	"time"

	"github.com/radar-alert/backend/internal/client/resend"
)

const (
	defaultFrom    = "Marmaradar <noreply@marmaradar.com>"
	defaultReplyTo = "support@marmaradar.com"
	defaultQueue   = 256
	defaultWorkers = 2
	sendTimeout    = 10 * time.Second
)

type job struct {
	to      string
	subject string
	html    string
	text    string
}

type Mailer struct {
	client  *resend.Client
	from    string
	replyTo string
	jobs    chan job
}

func NewMailer(client *resend.Client, from, replyTo string) *Mailer {
	return newMailer(client, from, replyTo, defaultQueue, defaultWorkers)
}

func newMailer(client *resend.Client, from, replyTo string, queueSize, workers int) *Mailer {
	if queueSize < 1 {
		queueSize = 1
	}
	m := &Mailer{
		client:  client,
		from:    strings.TrimSpace(from),
		replyTo: strings.TrimSpace(replyTo),
		jobs:    make(chan job, queueSize),
	}
	if m.from == "" {
		m.from = defaultFrom
	}
	if m.replyTo == "" {
		m.replyTo = defaultReplyTo
	}
	if m.Enabled() {
		for i := 0; i < workers; i++ {
			go m.worker()
		}
	}
	return m
}

func (m *Mailer) Enabled() bool {
	return m != nil && m.client != nil && m.client.Enabled()
}

func (m *Mailer) EnqueueWelcome(to string) {
	msg, err := renderWelcome(to)
	m.enqueueRendered(to, msg, err)
}

func (m *Mailer) EnqueuePasswordReset(to, resetURL string) {
	msg, err := renderPasswordReset(resetURL)
	m.enqueueRendered(to, msg, err)
}

func (m *Mailer) EnqueueNotification(to, subject, heading, body string) {
	subject = strings.TrimSpace(subject)
	heading = strings.TrimSpace(heading)
	if subject == "" || heading == "" {
		return
	}
	msg, err := renderNotification(subject, heading, body)
	m.enqueueRendered(to, msg, err)
}

func (m *Mailer) enqueueRendered(to string, msg rendered, err error) {
	if err != nil {
		slog.Warn("email template render failed", "error", err, "to", to)
		return
	}
	m.enqueue(job{
		to:      to,
		subject: msg.Subject,
		html:    msg.HTML,
		text:    msg.Text,
	})
}

func (m *Mailer) enqueue(j job) {
	if !m.Enabled() {
		return
	}
	if !Deliverable(j.to) {
		return
	}
	select {
	case m.jobs <- j:
	default:
		slog.Warn("email queue full, dropping message", "to", j.to, "subject", j.subject)
	}
}

func (m *Mailer) worker() {
	for j := range m.jobs {
		ctx, cancel := context.WithTimeout(context.Background(), sendTimeout)
		err := m.client.Send(ctx, resend.Message{
			From:    m.from,
			To:      []string{j.to},
			Subject: j.subject,
			HTML:    j.html,
			Text:    j.text,
			ReplyTo: m.replyTo,
		})
		cancel()
		if err != nil {
			slog.Warn("email send failed", "error", err, "to", j.to, "subject", j.subject)
		}
	}
}
