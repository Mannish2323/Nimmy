package proxy

import (
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strings"
	"time"
)

// Proxy forwards requests from Gateway to the target backend (Python AI Brain).
type Proxy struct {
	target *url.URL
	proxy  *httputil.ReverseProxy
}

// NewProxy creates a reverse proxy for targetURL.
func NewProxy(targetURL string) (*Proxy, error) {
	parsed, err := url.Parse(targetURL)
	if err != nil {
		return nil, err
	}

	rp := httputil.NewSingleHostReverseProxy(parsed)

	// Custom error handler for graceful degradation
	rp.ErrorHandler = func(w http.ResponseWriter, r *http.Request, err error) {
		log.Printf("[PROXY ERROR] Backend %s unreachable: %v", targetURL, err)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadGateway)
		w.Write([]byte(`{
			"error": "ai_brain_offline",
			"message": "Nimmy AI Brain backend is starting up or temporarily unreachable. Standby mode active.",
			"service": "nimmy-gateway",
			"status": "degraded"
		}`))
	}

	// Transport tuning
	rp.Transport = &http.Transport{
		MaxIdleConns:        100,
		MaxIdleConnsPerHost: 50,
		IdleConnTimeout:     90 * time.Second,
	}

	return &Proxy{
		target: parsed,
		proxy:  rp,
	}, nil
}

// ServeHTTP handles request proxying.
func (p *Proxy) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Strip prefix or preserve path
	r.Host = p.target.Host
	r.Header.Set("X-Forwarded-Host", r.Host)
	r.Header.Set("X-Gateway-Time", time.Now().UTC().Format(time.RFC3339))

	if strings.HasPrefix(r.URL.Path, "/api/v1") {
		p.proxy.ServeHTTP(w, r)
		return
	}

	p.proxy.ServeHTTP(w, r)
}
