package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"
	"bufio"

	"github.com/montanaflynn/stats"
	"github.com/pion/webrtc/v3"
)

type Offer struct{ SDP string `json:"sdp"` }
type Answer struct{ SDP string `json:"sdp"` }

type ClientMsg struct {
	Op     string `json:"op"`
	Model  string `json:"model,omitempty"`
	Prompt string `json:"prompt,omitempty"`
	Stream bool   `json:"stream,omitempty"`
	// Noise handshake messages
	NoiseInit     []byte `json:"noise_init,omitempty"`
	NoiseResponse []byte `json:"noise_response,omitempty"`
}

type ServerMsg struct {
	Op      string `json:"op"`
	Content string `json:"content,omitempty"`
	Error   string `json:"error,omitempty"`
	// Noise handshake messages
	NoiseInit     []byte `json:"noise_init,omitempty"`
	NoiseResponse []byte `json:"noise_response,omitempty"`
	// E2E status
	E2EEstablished bool   `json:"e2e_established,omitempty"`
	PublicKey      string `json:"public_key,omitempty"`
}

// TTFTMetrics tracks Time To First Token measurements
type TTFTMetrics struct {
	mu          sync.Mutex
	measurements []float64
}

func (m *TTFTMetrics) Record(ttft time.Duration) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.measurements = append(m.measurements, float64(ttft.Milliseconds()))
}

func (m *TTFTMetrics) GetStats() (p50, p90 float64, count int) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if len(m.measurements) == 0 {
		return 0, 0, 0
	}
	data := stats.LoadRawData(m.measurements)
	p50, _ = stats.Percentile(data, 50)
	p90, _ = stats.Percentile(data, 90)
	return p50, p90, len(m.measurements)
}

var (
	ttftMetrics   = &TTFTMetrics{}
	noiseManager  *NoiseManager
	strictLocalMode = true
)

func main() {
	// Initialize Ollama manager for model optimization
	initOllamaManager()
	initFastOllama()
	
	// Initialize Noise manager
	var err error
	devMode := os.Getenv("DEV_MODE") == "1"
	noiseManager, err = NewNoiseManager(devMode)
	if err != nil {
		log.Fatalf("Failed to initialize Noise: %v", err)
	}
	log.Printf("Noise public key: %s", noiseManager.GetPublicKey())

	// Check Strict Local Mode
	if os.Getenv("DISABLE_STRICT_LOCAL") == "1" {
		strictLocalMode = false
		log.Println("WARNING: Strict Local Mode is DISABLED")
	} else {
		log.Println("Strict Local Mode is ENABLED (default)")
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) { 
		fmt.Fprintln(w, "ok") 
	})
	mux.HandleFunc("/signaling/offer", handleOffer)
	mux.HandleFunc("/metrics/ttft", handleTTFTMetrics)
	mux.HandleFunc("/noise/pubkey", handleNoisePubKey)
	mux.HandleFunc("/api/chat", handleChatProxy)
	
	addr := ":8443"
	log.Printf("listening on %s", addr)
	
	// Create custom server with local-only listener if strict mode
	server := &http.Server{
		Addr:    addr,
		Handler: cors(localOnly(mux)),
	}
	
	if strictLocalMode {
		// Custom listener that only accepts local connections
		ln, err := net.Listen("tcp", addr)
		if err != nil {
			log.Fatal(err)
		}
		log.Fatal(server.Serve(&strictLocalListener{ln}))
	} else {
		log.Fatal(server.ListenAndServe())
	}
}

// strictLocalListener wraps a listener to only accept local connections
type strictLocalListener struct {
	net.Listener
}

func (s *strictLocalListener) Accept() (net.Conn, error) {
	for {
		conn, err := s.Listener.Accept()
		if err != nil {
			return nil, err
		}
		
		// Check if connection is from local network
		if isLocalConnection(conn) {
			return conn, nil
		}
		
		// Reject non-local connections
		conn.Close()
		log.Printf("Rejected non-local connection from %s", conn.RemoteAddr())
	}
}

func isLocalConnection(conn net.Conn) bool {
	addr := conn.RemoteAddr().String()
	host, _, err := net.SplitHostPort(addr)
	if err != nil {
		return false
	}
	
	ip := net.ParseIP(host)
	if ip == nil {
		return false
	}
	
	// Allow loopback
	if ip.IsLoopback() {
		return true
	}
	
	// Allow private networks (RFC1918)
	if ip.IsPrivate() {
		return true
	}
	
	// Allow link-local
	if ip.IsLinkLocalUnicast() || ip.IsLinkLocalMulticast() {
		return true
	}
	
	// Check for Tailscale CGNAT range (100.64.0.0/10)
	if ip.To4() != nil {
		if ip[0] == 100 && ip[1] >= 64 && ip[1] <= 127 {
			return true
		}
	}
	
	return false
}

func cors(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// In strict local mode, only allow CORS from local origins
		origin := r.Header.Get("Origin")
		if strictLocalMode && origin != "" {
			// Parse origin URL properly
			if strings.HasPrefix(origin, "file://") {
				// Allow file:// origins for local HTML files
			} else if strings.HasPrefix(origin, "http://localhost") || 
					  strings.HasPrefix(origin, "http://127.0.0.1") ||
					  strings.HasPrefix(origin, "http://[::1]") {
				// Allow localhost origins
			} else {
				// Check if it's a local IP
				if u, err := url.Parse(origin); err == nil {
					if host, _, err := net.SplitHostPort(u.Host); err == nil {
						if ip := net.ParseIP(host); ip != nil && !isLocalIP(ip) {
							http.Error(w, "Forbidden: non-local origin", 403)
							return
						}
					} else {
						// No port in URL
						if ip := net.ParseIP(u.Host); ip != nil && !isLocalIP(ip) {
							http.Error(w, "Forbidden: non-local origin", 403)
							return
						}
					}
				}
			}
		}
		
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Headers", "content-type")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		if r.Method == http.MethodOptions {
			w.WriteHeader(204)
			return
		}
		h.ServeHTTP(w, r)
	})
}

func localOnly(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strictLocalMode {
			// Check if request is from local network
			host, _, err := net.SplitHostPort(r.RemoteAddr)
			if err != nil {
				http.Error(w, "Invalid remote address", 400)
				return
			}
			
			ip := net.ParseIP(host)
			if !isLocalIP(ip) {
				http.Error(w, "Forbidden: non-local access", 403)
				return
			}
		}
		h.ServeHTTP(w, r)
	})
}

func isLocalIP(ip net.IP) bool {
	if ip == nil {
		return false
	}
	return ip.IsLoopback() || ip.IsPrivate() || ip.IsLinkLocalUnicast() || 
		(ip.To4() != nil && ip[0] == 100 && ip[1] >= 64 && ip[1] <= 127) // Tailscale CGNAT
}

func handleNoisePubKey(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"public_key": noiseManager.GetPublicKey(),
	})
}

func handleTTFTMetrics(w http.ResponseWriter, r *http.Request) {
	p50, p90, count := ttftMetrics.GetStats()
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"p50_ms": p50,
		"p90_ms": p90,
		"count":  count,
	})
}

func handleOffer(w http.ResponseWriter, r *http.Request) {
	var off Offer
	if err := json.NewDecoder(r.Body).Decode(&off); err != nil {
		http.Error(w, err.Error(), 400)
		return
	}

	api := webrtc.NewAPI()
	pc, err := api.NewPeerConnection(webrtc.Configuration{
		ICEServers: []webrtc.ICEServer{
			{URLs: []string{"stun:stun.l.google.com:19302"}},
			{URLs: envURLs("TURN_URLS"), Username: os.Getenv("TURN_USER"), Credential: os.Getenv("TURN_PASS")},
		},
	})
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	defer pc.Close()

	// Generate peer ID for this connection
	peerID := fmt.Sprintf("peer-%d", time.Now().UnixNano())
	var e2eEstablished bool
	var sessionMux sync.RWMutex

	dc, err := pc.CreateDataChannel("llm", nil)
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	
	dc.OnOpen(func() {
		// Send server public key when channel opens
		_ = dc.SendText(mustJSON(ServerMsg{
			Op:        "noise_pubkey",
			PublicKey: noiseManager.GetPublicKey(),
		}))
	})
	
	dc.OnClose(func() {
		// Clean up Noise session
		noiseManager.CloseSession(peerID)
		log.Printf("DataChannel closed, removed session for %s", peerID)
	})
	
	dc.OnMessage(func(msg webrtc.DataChannelMessage) {
		// Try to decrypt if E2E is established
		sessionMux.RLock()
		isE2E := e2eEstablished
		sessionMux.RUnlock()

		var msgData []byte
		if isE2E {
			// Try to decrypt
			decrypted, err := noiseManager.Decrypt(peerID, msg.Data)
			if err != nil {
				log.Printf("Failed to decrypt message: %v", err)
				_ = dc.SendText(mustJSON(ServerMsg{Op: "error", Error: "decryption failed"}))
				return
			}
			msgData = decrypted
		} else {
			msgData = msg.Data
		}

		var cm ClientMsg
		if err := json.Unmarshal(msgData, &cm); err != nil {
			_ = dc.SendText(mustJSON(ServerMsg{Op: "error", Error: "bad json"}))
			return
		}

		switch cm.Op {
		case "noise_init":
			// Handle Noise handshake initiation
			response, err := noiseManager.HandleHandshake(peerID, cm.NoiseInit)
			if err != nil {
				_ = dc.SendText(mustJSON(ServerMsg{Op: "error", Error: fmt.Sprintf("handshake failed: %v", err)}))
				return
			}
			_ = dc.SendText(mustJSON(ServerMsg{Op: "noise_response", NoiseResponse: response}))
			
			sessionMux.Lock()
			e2eEstablished = true
			sessionMux.Unlock()
			
			_ = dc.SendText(mustJSON(ServerMsg{Op: "e2e_established", E2EEstablished: true}))
			log.Printf("E2E established with %s", peerID)

		case "ping":
			response := mustJSON(ServerMsg{Op: "pong"})
			if isE2E {
				encrypted, _ := noiseManager.Encrypt(peerID, []byte(response))
				_ = dc.Send(encrypted)
			} else {
				_ = dc.SendText(response)
			}

		case "chat":
			model := cm.Model
			if model == "" {
				model = env("OLLAMA_MODEL", "qwen2.5:3b") // Use faster default model
			}
			// Ensure model is warmed up
			if globalOllamaManager != nil {
				globalOllamaManager.WarmupModel(model)
				globalOllamaManager.UpdateLastUsed(model)
			}
			go proxyOllamaStream(dc, peerID, model, cm.Prompt, true, isE2E)

		default:
			_ = dc.SendText(mustJSON(ServerMsg{Op: "error", Error: "unknown op"}))
		}
	})

	offer := webrtc.SessionDescription{Type: webrtc.SDPTypeOffer, SDP: off.SDP}
	if err := pc.SetRemoteDescription(offer); err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	
	answer, err := pc.CreateAnswer(nil)
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	
	done := webrtc.GatheringCompletePromise(pc)
	if err := pc.SetLocalDescription(answer); err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	<-done
	
	_ = json.NewEncoder(w).Encode(Answer{SDP: pc.LocalDescription().SDP})
}

func proxyOllamaStream(dc *webrtc.DataChannel, peerID, model, prompt string, stream bool, isE2E bool) {
	// Record start time for TTFT
	startTime := time.Now()
	firstTokenSent := false
	
	// Use fast client if available
	if globalFastClient != nil {
		// Optimize prompt
		prompt = OptimizePrompt(prompt)
		
		// Select best model if not specified
		if model == "" || model == "qwen2.5:3b" {
			model = GetFastestModel(len(prompt))
		}
		
		globalFastClient.StreamChat(model, prompt, func(content string, err error) {
			if err != nil {
				sendMessage(dc, peerID, ServerMsg{Op: "error", Error: err.Error()}, isE2E)
				return
			}
			
			if content != "" {
				// Record TTFT on first token
				if !firstTokenSent {
					ttft := time.Since(startTime)
					ttftMetrics.Record(ttft)
					log.Printf("TTFT: %dms (model: %s)", ttft.Milliseconds(), model)
					firstTokenSent = true
				}
				
				sendMessage(dc, peerID, ServerMsg{Op: "delta", Content: content}, isE2E)
			}
		})
		
		sendMessage(dc, peerID, ServerMsg{Op: "done"}, isE2E)
		return
	}
	
	// Get optimized settings
	options := map[string]interface{}{
		"num_predict": 512,
	}
	if globalOllamaManager != nil {
		optSettings := globalOllamaManager.GetOptimizedSettings(model)
		for k, v := range optSettings {
			options[k] = v
		}
	}
	
	payload := map[string]any{
		"model":       model,
		"stream":      true,
		"messages":    []map[string]string{{"role": "user", "content": prompt}},
		"options":     options,
	}
	
	b, _ := json.Marshal(payload)
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	
	// Check if Ollama URL would violate strict local mode
	ollamaURL := env("OLLAMA_URL", "http://127.0.0.1:11434")
	if strictLocalMode && !isLocalURL(ollamaURL) {
		sendMessage(dc, peerID, ServerMsg{Op: "error", Error: "Ollama URL violates strict local mode"}, isE2E)
		return
	}
	
	req, _ := http.NewRequestWithContext(ctx, "POST", ollamaURL+"/api/chat", bytes.NewReader(b))
	req.Header.Set("Content-Type", "application/json")
	
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		sendMessage(dc, peerID, ServerMsg{Op: "error", Error: "ollama connect failed"}, isE2E)
		return
	}
	defer resp.Body.Close()
	
	dec := json.NewDecoder(resp.Body)
	var ln struct {
		Model   string `json:"model"`
		Message struct{ Role, Content string } `json:"message"`
		Done    bool `json:"done"`
	}
	
	for {
		if err := dec.Decode(&ln); err != nil {
			if err == io.EOF {
				break
			}
			sendMessage(dc, peerID, ServerMsg{Op: "error", Error: "decode error"}, isE2E)
			return
		}
		
		if ln.Message.Content != "" {
			// Record TTFT on first token
			if !firstTokenSent {
				ttft := time.Since(startTime)
				ttftMetrics.Record(ttft)
				log.Printf("TTFT: %dms", ttft.Milliseconds())
				firstTokenSent = true
			}
			
			sendMessage(dc, peerID, ServerMsg{Op: "delta", Content: ln.Message.Content}, isE2E)
		}
		
		if ln.Done {
			break
		}
	}
	
	sendMessage(dc, peerID, ServerMsg{Op: "done"}, isE2E)
}

func sendMessage(dc *webrtc.DataChannel, peerID string, msg ServerMsg, isE2E bool) error {
	data := mustJSON(msg)
	if isE2E {
		encrypted, err := noiseManager.Encrypt(peerID, []byte(data))
		if err != nil {
			return err
		}
		return dc.Send(encrypted)
	}
	return dc.SendText(data)
}

func isLocalURL(urlStr string) bool {
	if strings.HasPrefix(urlStr, "http://127.0.0.1") || 
	   strings.HasPrefix(urlStr, "http://localhost") ||
	   strings.HasPrefix(urlStr, "http://[::1]") {
		return true
	}
	
	// Parse URL and check if host is local
	if strings.Contains(urlStr, "://") {
		parts := strings.Split(urlStr, "://")
		if len(parts) > 1 {
			hostPort := strings.Split(parts[1], "/")[0]
			host := strings.Split(hostPort, ":")[0]
			ip := net.ParseIP(host)
			if ip != nil {
				return isLocalIP(ip)
			}
		}
	}
	
	return false
}

func env(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func envURLs(k string) []string {
	if v := os.Getenv(k); v != "" {
		return []string{v}
	}
	return nil
}

func mustJSON(v any) string {
	b, _ := json.Marshal(v)
	return string(b)
}

// handleChatProxy proxies chat requests to Ollama with TTFT tracking
func handleChatProxy(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Read request body
	var requestBody map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&requestBody); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Get model or use optimized default
	model, _ := requestBody["model"].(string)
	if model == "" {
		// Auto-select based on prompt length
		if messages, ok := requestBody["messages"].([]interface{}); ok && len(messages) > 0 {
			if msg, ok := messages[0].(map[string]interface{}); ok {
				if content, ok := msg["content"].(string); ok {
					model = GetFastestModel(len(content))
				}
			}
		}
		if model == "" {
			model = "qwen2.5:3b"
		}
		requestBody["model"] = model
	}

	// Add optimized settings
	if _, hasOptions := requestBody["options"]; !hasOptions && globalOllamaManager != nil {
		requestBody["options"] = globalOllamaManager.GetOptimizedSettings(model)
	}

	// Forward to Ollama
	ollamaURL := env("OLLAMA_URL", "http://127.0.0.1:11434")
	
	body, _ := json.Marshal(requestBody)
	proxyReq, err := http.NewRequest("POST", ollamaURL+"/api/chat", bytes.NewReader(body))
	if err != nil {
		http.Error(w, "Failed to create request", http.StatusInternalServerError)
		return
	}

	proxyReq.Header.Set("Content-Type", "application/json")

	// Track TTFT
	startTime := time.Now()
	firstTokenSent := false

	client := &http.Client{Timeout: 2 * time.Minute}
	resp, err := client.Do(proxyReq)
	if err != nil {
		http.Error(w, "Failed to connect to Ollama", http.StatusServiceUnavailable)
		return
	}
	defer resp.Body.Close()

	// Set headers for streaming
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")

	// Stream response
	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "Streaming not supported", http.StatusInternalServerError)
		return
	}

	scanner := bufio.NewScanner(resp.Body)
	for scanner.Scan() {
		line := scanner.Bytes()
		
		// Track TTFT on first content
		if !firstTokenSent && bytes.Contains(line, []byte(`"content"`)) {
			ttft := time.Since(startTime)
			ttftMetrics.Record(ttft)
			log.Printf("Proxy TTFT: %dms (model: %s)", ttft.Milliseconds(), model)
			firstTokenSent = true
		}

		// Write to response
		w.Write(line)
		w.Write([]byte("\n"))
		flusher.Flush()
	}
}