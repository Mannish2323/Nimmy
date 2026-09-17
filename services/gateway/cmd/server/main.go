// 🟣 NIMMY API Gateway — Go
// ==========================
// High-concurrency API gateway for Nimmy services.
// Handles routing, auth, rate-limiting, WebSocket, and service orchestration.

package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	mux := http.NewServeMux()

	// Health check
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, `{"service":"nimmy-gateway","status":"healthy","version":"0.1.0"}`)
	})

	// Root
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprint(w, `{"service":"nimmy-gateway","status":"online","version":"0.1.0"}`)
	})

	log.Printf("🟣 Nimmy Gateway starting on port %s", port)
	if err := http.ListenAndServe(":"+port, mux); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
