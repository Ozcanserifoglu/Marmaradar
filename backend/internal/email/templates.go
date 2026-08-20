package email

import (
	"bytes"
	"embed"
	"fmt"
	"html/template"
	"strings"
	texttemplate "text/template"
)

//go:embed templates/*
var templateFS embed.FS

var (
	welcomeHTML      = mustHTML("templates/welcome.html")
	welcomeText      = mustText("templates/welcome.txt")
	resetHTML        = mustHTML("templates/password_reset.html")
	resetText        = mustText("templates/password_reset.txt")
	notificationHTML = mustHTML("templates/notification.html")
	notificationText = mustText("templates/notification.txt")
)

type welcomeData struct {
	Email string
}

type resetData struct {
	ResetURL string
}

type notificationData struct {
	Subject string
	Heading string
	Body    string
}

type rendered struct {
	Subject string
	HTML    string
	Text    string
}

func renderWelcome(to string) (rendered, error) {
	data := welcomeData{Email: strings.TrimSpace(to)}
	htmlBody, err := execHTML(welcomeHTML, data)
	if err != nil {
		return rendered{}, err
	}
	textBody, err := execText(welcomeText, data)
	if err != nil {
		return rendered{}, err
	}
	return rendered{
		Subject: "Marmaradar'a hoş geldiniz",
		HTML:    htmlBody,
		Text:    textBody,
	}, nil
}

func renderPasswordReset(resetURL string) (rendered, error) {
	data := resetData{ResetURL: resetURL}
	htmlBody, err := execHTML(resetHTML, data)
	if err != nil {
		return rendered{}, err
	}
	textBody, err := execText(resetText, data)
	if err != nil {
		return rendered{}, err
	}
	return rendered{
		Subject: "Marmaradar şifre sıfırlama",
		HTML:    htmlBody,
		Text:    textBody,
	}, nil
}

func renderNotification(subject, heading, body string) (rendered, error) {
	data := notificationData{
		Subject: subject,
		Heading: heading,
		Body:    body,
	}
	htmlBody, err := execHTML(notificationHTML, data)
	if err != nil {
		return rendered{}, err
	}
	textBody, err := execText(notificationText, data)
	if err != nil {
		return rendered{}, err
	}
	return rendered{
		Subject: subject,
		HTML:    htmlBody,
		Text:    textBody,
	}, nil
}

func mustHTML(path string) *template.Template {
	t, err := template.ParseFS(templateFS, path)
	if err != nil {
		panic(err)
	}
	return t
}

func mustText(path string) *texttemplate.Template {
	t, err := texttemplate.ParseFS(templateFS, path)
	if err != nil {
		panic(err)
	}
	return t
}

func execHTML(t *template.Template, data any) (string, error) {
	var buf bytes.Buffer
	if err := t.Execute(&buf, data); err != nil {
		return "", fmt.Errorf("render html template: %w", err)
	}
	return buf.String(), nil
}

func execText(t *texttemplate.Template, data any) (string, error) {
	var buf bytes.Buffer
	if err := t.Execute(&buf, data); err != nil {
		return "", fmt.Errorf("render text template: %w", err)
	}
	return buf.String(), nil
}
