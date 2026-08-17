package georestrict

import (
	"bufio"
	"bytes"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"strings"

	_ "embed"
)

// CIDR snapshots from ipdeny.com aggregated country zones (TR).
//
//go:embed data/tr-ipv4.txt
var trIPv4 []byte

//go:embed data/tr-ipv6.txt
var trIPv6 []byte

// Guard denies requests from public IPs outside the allowed countries.
// Private, loopback, and link-local addresses are always allowed so Docker
// and GCP internal health checks keep working.
type Guard struct {
	nets []*net.IPNet
}

// New returns a Guard for the given ISO 3166-1 alpha-2 country codes.
// An empty list disables restriction (nil Guard is also a no-op).
func New(countries []string) (*Guard, error) {
	var nets []*net.IPNet
	for _, raw := range countries {
		cc := strings.ToUpper(strings.TrimSpace(raw))
		if cc == "" {
			continue
		}
		switch cc {
		case "TR":
			parsed, err := parseCIDRs(trIPv4)
			if err != nil {
				return nil, fmt.Errorf("turkey ipv4 cidrs: %w", err)
			}
			nets = append(nets, parsed...)
			parsed, err = parseCIDRs(trIPv6)
			if err != nil {
				return nil, fmt.Errorf("turkey ipv6 cidrs: %w", err)
			}
			nets = append(nets, parsed...)
		default:
			return nil, fmt.Errorf("unsupported GEO_RESTRICT_COUNTRIES value %q (only TR is supported)", cc)
		}
	}
	if len(nets) == 0 {
		return nil, nil
	}
	return &Guard{nets: nets}, nil
}

func parseCIDRs(data []byte) ([]*net.IPNet, error) {
	var nets []*net.IPNet
	sc := bufio.NewScanner(bytes.NewReader(data))
	lineNo := 0
	for sc.Scan() {
		lineNo++
		line := strings.TrimSpace(sc.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		_, network, err := net.ParseCIDR(line)
		if err != nil {
			return nil, fmt.Errorf("line %d: %w", lineNo, err)
		}
		nets = append(nets, network)
	}
	if err := sc.Err(); err != nil {
		return nil, err
	}
	return nets, nil
}

func ParseCountries(raw string) []string {
	if strings.TrimSpace(raw) == "" {
		return nil
	}
	parts := strings.Split(raw, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p != "" {
			out = append(out, p)
		}
	}
	return out
}

// Allowed reports whether ip may reach the API. A nil Guard allows everything;
// an unparseable address is rejected.
func (g *Guard) Allowed(ip net.IP) bool {
	if g == nil {
		return true
	}
	if ip == nil {
		return false
	}
	if isTrustedHop(ip) {
		return true
	}
	for _, n := range g.nets {
		if n.Contains(ip) {
			return true
		}
	}
	return false
}

func (g *Guard) Middleware(next http.Handler) http.Handler {
	if g == nil {
		return next
	}
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/health" {
			next.ServeHTTP(w, r)
			return
		}
		ip := requestIP(r)
		if g.Allowed(ip) {
			next.ServeHTTP(w, r)
			return
		}
		slog.Info("geo restricted request", "ip", ipString(ip), "path", r.URL.Path)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusForbidden)
		_, _ = w.Write([]byte(`{"error":"bu servis yalnızca Türkiye'den erişilebilir"}`))
	})
}

func requestIP(r *http.Request) net.IP {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		host = r.RemoteAddr
	}
	remote := net.ParseIP(host)

	if remote != nil && !isTrustedHop(remote) {
		return remote
	}

	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		parts := strings.Split(xff, ",")
		for i := len(parts) - 1; i >= 0; i-- {
			ip := net.ParseIP(strings.TrimSpace(parts[i]))
			if ip != nil && !isTrustedHop(ip) {
				return ip
			}
		}
	}
	if xrip := strings.TrimSpace(r.Header.Get("X-Real-IP")); xrip != "" {
		if ip := net.ParseIP(xrip); ip != nil {
			return ip
		}
	}
	return remote
}

func isTrustedHop(ip net.IP) bool {
	return ip.IsLoopback() || ip.IsPrivate() || ip.IsLinkLocalUnicast() || ip.IsLinkLocalMulticast()
}

func ipString(ip net.IP) string {
	if ip == nil {
		return ""
	}
	return ip.String()
}
