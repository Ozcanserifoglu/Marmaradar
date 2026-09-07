package apidocs

import (
	"embed"
	"net/http"

	"github.com/radar-alert/backend/docs"
	"github.com/swaggo/swag"
)

//go:embed apiusage.html scalar.html
var docsFS embed.FS

type Handler struct{}

func NewHandler() *Handler {
	return &Handler{}
}

func (h *Handler) ServeUI(w http.ResponseWriter, r *http.Request) {
	h.serveFile(w, "apiusage.html")
}

func (h *Handler) ServeScalar(w http.ResponseWriter, r *http.Request) {
	h.serveFile(w, "scalar.html")
}

func (h *Handler) serveFile(w http.ResponseWriter, name string) {
	b, err := docsFS.ReadFile(name)
	if err != nil {
		http.Error(w, "docs unavailable", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Header().Set("Cache-Control", "public, max-age=300")
	w.Write(b)
}

func (h *Handler) ServeSpec(w http.ResponseWriter, r *http.Request) {
	spec, err := swag.ReadDoc(docs.SwaggerInfo.InstanceName())
	if err != nil {
		http.Error(w, "openapi spec unavailable", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Cache-Control", "public, max-age=60")
	w.Write([]byte(spec))
}
