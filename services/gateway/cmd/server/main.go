// 🟣 NIMMY API Gateway — Go
// ==========================
// High-concurrency API gateway for Nimmy services.
// Handles routing, rate-limiting, CORS, WebSocket multiplexing, and AI Brain proxying.

package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/Mannish2323/nimmy/services/gateway/internal/middleware"
	"github.com/Mannish2323/nimmy/services/gateway/internal/proxy"
	"github.com/Mannish2323/nimmy/services/gateway/internal/websocket"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	aiBrainURL := os.Getenv("AI_BRAIN_URL")
	if aiBrainURL == "" {
		aiBrainURL = "http://localhost:8000"
	}

	startTime := time.Now()

	// 1. Initialize WebSocket Hub
	hub := websocket.NewHub()
	go hub.Run()

	// 2. Initialize Reverse Proxy to AI Brain
	aiProxy, err := proxy.NewProxy(aiBrainURL)
	if err != nil {
		log.Fatalf("Failed to initialize reverse proxy: %v", err)
	}

	// 3. Rate Limiter (50 req/sec, burst capacity 100)
	rateLimiter := middleware.NewRateLimiter(50.0, 100.0)

	// 4. HTTP Router
	mux := http.NewServeMux()

	// Health Check
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, `{"service":"nimmy-gateway","status":"healthy","version":"1.0.0"}`)
	})

	// Cluster Telemetry & Status
	mux.HandleFunc("/api/status", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		status := map[string]interface{}{
			"service":        "nimmy-gateway",
			"status":         "operational",
			"version":        "1.0.0",
			"uptime_seconds": int(time.Since(startTime).Seconds()),
			"active_clients": hub.ActiveClientsCount(),
			"ai_brain_target": aiBrainURL,
			"timestamp":      time.Now().UTC().Format(time.RFC3339),
		}
		json.NewEncoder(w).Encode(status)
	})

	// WebSocket Multiplexer
	mux.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		hub.ServeWebSocket(w, r)
	})

	// Reverse Proxy to Python AI Brain (/api/v1/...)
	mux.HandleFunc("/api/v1/", func(w http.ResponseWriter, r *http.Request) {
		aiProxy.ServeHTTP(w, r)
	})

	// Root Status
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" {
			http.NotFound(w, r)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{
			"service": "nimmy-gateway",
			"status": "online",
			"version": "1.0.0",
			"endpoints": ["/health", "/api/status", "/ws", "/api/v1/chat", "/api/v1/memory", "/api/v1/summarize", "/api/v1/tasks/parse"]
		}`)
	})

	// 5. Wrap Middlewares: CORS -> Rate Limiter -> Logger
	handler := middleware.CORS(rateLimiter.Limit(middleware.Logger(mux)))

	server := &http.Server{
		Addr:         ":" + port,
		Handler:      handler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// 6. Graceful Shutdown Listener
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)

	go func() {
		log.Printf("🟣 Nimmy API Gateway listening on port %s", port)
		log.Printf("├── WebSocket Hub: ws://localhost:%s/ws", port)
		log.Printf("└── AI Brain Proxy: %s/api/v1/ -> %s", "http://localhost:"+port, aiBrainURL)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server listen failed: %v", err)
		}
	}()

	<-stop
	log.Println("Shutting down Nimmy Gateway gracefully...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Printf("Gateway forced shutdown error: %v", err)
	} else {
		log.Println("Gateway stopped cleanly.")
	}
}
