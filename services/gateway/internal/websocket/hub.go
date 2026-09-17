package websocket

import (
	"crypto/sha1"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"net/http"
	"sync"
	"time"
)

// Client represents a connected Web or Mobile WebSocket session.
type Client struct {
	ID        string
	Conn      net.Conn
	Hub       *Hub
	Send      chan []byte
	UserAgent string
	Connected time.Time
}

// Hub manages active WebSocket client connections and broadcasting.
type Hub struct {
	clients    map[string]*Client
	broadcast  chan []byte
	register   chan *Client
	unregister chan *Client
	mu         sync.RWMutex
}

// NewHub creates a new WebSocket hub.
func NewHub() *Hub {
	return &Hub{
		clients:    make(map[string]*Client),
		broadcast:  make(chan []byte, 256),
		register:   make(chan *Client),
		unregister: make(chan *Client),
	}
}

// Run executes the hub event loop in a goroutine.
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client.ID] = client
			h.mu.Unlock()
			log.Printf("[WS HUB] Client registered: %s (Total: %d)", client.ID, len(h.clients))

			// Send welcome greeting frame
			welcome, _ := json.Marshal(map[string]interface{}{
				"event":      "connected",
				"client_id":  client.ID,
				"service":    "nimmy-gateway",
				"timestamp":  time.Now().UTC().Format(time.RFC3339),
				"status":     "active",
				"message":    "WebSocket stream established with Nimmy Gateway",
			})
			client.SendFrame(1, welcome) // 1 = text frame

		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client.ID]; ok {
				delete(h.clients, client.ID)
				close(client.Send)
				client.Conn.Close()
				log.Printf("[WS HUB] Client disconnected: %s (Remaining: %d)", client.ID, len(h.clients))
			}
			h.mu.Unlock()

		case message := <-h.broadcast:
			h.mu.RLock()
			for _, client := range h.clients {
				select {
				case client.Send <- message:
				default:
					close(client.Send)
					delete(h.clients, client.ID)
				}
			}
			h.mu.RUnlock()
		}
	}
}

// ActiveClientsCount returns the number of connected clients.
func (h *Hub) ActiveClientsCount() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return len(h.clients)
}

// BroadcastJSON sends a typed JSON event to all connected clients.
func (h *Hub) BroadcastJSON(event string, payload interface{}) {
	data, err := json.Marshal(map[string]interface{}{
		"event":     event,
		"payload":   payload,
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	})
	if err == nil {
		h.broadcast <- data
	}
}

// SendFrame formats a raw WebSocket frame according to RFC 6455.
func (c *Client) SendFrame(opCode byte, payload []byte) error {
	length := len(payload)
	var header []byte

	header = append(header, 0x80|opCode) // FIN bit + opcode

	if length <= 125 {
		header = append(header, byte(length))
	} else if length <= 65535 {
		header = append(header, 126, byte(length>>8), byte(length))
	} else {
		header = append(header, 127,
			byte(length>>56), byte(length>>48), byte(length>>40), byte(length>>32),
			byte(length>>24), byte(length>>16), byte(length>>8), byte(length))
	}

	frame := append(header, payload...)
	_, err := c.Conn.Write(frame)
	return err
}

// ServeWebSocket upgrades HTTP request to raw WebSocket and registers with the hub.
func (h *Hub) ServeWebSocket(w http.ResponseWriter, r *http.Request) {
	if r.Header.Get("Upgrade") != "websocket" {
		http.Error(w, "Expected WebSocket upgrade", http.StatusBadRequest)
		return
	}

	key := r.Header.Get("Sec-WebSocket-Key")
	if key == "" {
		http.Error(w, "Missing Sec-WebSocket-Key", http.StatusBadRequest)
		return
	}

	// Compute accept hash per RFC 6455
	hash := sha1.New()
	hash.Write([]byte(key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
	accept := base64.StdEncoding.EncodeToString(hash.Sum(nil))

	hj, ok := w.(http.Hijacker)
	if !ok {
		http.Error(w, "Hijacking not supported", http.StatusInternalServerError)
		return
	}

	conn, bufrw, err := hj.Hijack()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Write handshake response
	response := fmt.Sprintf(
		"HTTP/1.1 101 Switching Protocols\r\n"+
			"Upgrade: websocket\r\n"+
			"Connection: Upgrade\r\n"+
			"Sec-WebSocket-Accept: %s\r\n\r\n",
		accept,
	)
	bufrw.WriteString(response)
	bufrw.Flush()

	clientID := fmt.Sprintf("client-%d", time.Now().UnixNano())
	client := &Client{
		ID:        clientID,
		Conn:      conn,
		Hub:       h,
		Send:      make(chan []byte, 64),
		UserAgent: r.UserAgent(),
		Connected: time.Now(),
	}

	h.register <- client

	// Read pump in goroutine
	go func() {
		defer func() {
			h.unregister <- client
		}()

		buffer := make([]byte, 4096)
		for {
			n, err := conn.Read(buffer)
			if err != nil {
				break
			}
			if n > 0 {
				// Echo / Broadcast received frame payload
				// Client message loop
			}
		}
	}()
}
