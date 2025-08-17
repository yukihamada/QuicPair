package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"bufio"
	"io"
	"log"
	"net/http"
	"strings"
	"sync"
	"time"
)

// FastOllamaClient provides optimized Ollama communication
type FastOllamaClient struct {
	client       *http.Client
	baseURL      string
	mu           sync.RWMutex
	connections  map[string]*http.Client
}

// NewFastOllamaClient creates an optimized Ollama client
func NewFastOllamaClient(baseURL string) *FastOllamaClient {
	transport := &http.Transport{
		MaxIdleConns:        100,
		MaxIdleConnsPerHost: 100,
		IdleConnTimeout:     90 * time.Second,
		DisableCompression:  true, // Disable compression for lower latency
		ForceAttemptHTTP2:   false, // HTTP/1.1 is faster for local connections
	}

	return &FastOllamaClient{
		client: &http.Client{
			Transport: transport,
			Timeout:   30 * time.Second,
		},
		baseURL:     baseURL,
		connections: make(map[string]*http.Client),
	}
}

// StreamChat streams chat responses with minimal latency
func (fc *FastOllamaClient) StreamChat(model, prompt string, callback func(string, error)) {
	// Use minimal options for fastest response
	payload := map[string]interface{}{
		"model":    model,
		"messages": []map[string]string{{"role": "user", "content": prompt}},
		"stream":   true,
		"options": map[string]interface{}{
			"num_predict":     512,
			"temperature":     0.7,
			"top_k":          40,
			"top_p":          0.9,
			"repeat_penalty": 1.1,
			"seed":           42, // Fixed seed for consistency
			"num_thread":     4,  // Optimal for most systems
		},
	}

	// For very short prompts, use even more aggressive settings
	if len(prompt) < 50 {
		payload["options"].(map[string]interface{})["num_ctx"] = 512
		payload["options"].(map[string]interface{})["num_batch"] = 256
	}

	body, _ := json.Marshal(payload)
	req, err := http.NewRequest("POST", fc.baseURL+"/api/chat", bytes.NewReader(body))
	if err != nil {
		callback("", err)
		return
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Connection", "keep-alive")

	resp, err := fc.client.Do(req)
	if err != nil {
		callback("", err)
		return
	}
	defer resp.Body.Close()

	// Use a buffered reader for better performance
	reader := bufio.NewReader(resp.Body)
	decoder := json.NewDecoder(reader)

	firstToken := true
	for {
		var msg struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
			Done bool `json:"done"`
		}

		if err := decoder.Decode(&msg); err != nil {
			if err == io.EOF {
				break
			}
			callback("", err)
			return
		}

		if msg.Message.Content != "" {
			if firstToken {
				firstToken = false
				// Log first token timing
				log.Printf("⚡ First token received")
			}
			callback(msg.Message.Content, nil)
		}

		if msg.Done {
			break
		}
	}
}

// PreloadModel ensures a model is loaded and ready
func (fc *FastOllamaClient) PreloadModel(model string) error {
	log.Printf("⏳ Preloading model: %s", model)

	// Use generate endpoint with keep_alive to load model
	payload := map[string]interface{}{
		"model":      model,
		"prompt":     "",
		"keep_alive": "5m",
	}

	body, _ := json.Marshal(payload)
	req, err := http.NewRequest("POST", fc.baseURL+"/api/generate", bytes.NewReader(body))
	if err != nil {
		return err
	}

	req.Header.Set("Content-Type", "application/json")
	resp, err := fc.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("preload failed: status %d", resp.StatusCode)
	}

	// Read response to ensure model is loaded
	var result map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&result)

	log.Printf("✅ Model %s preloaded", model)
	return nil
}

// GetFastestModel returns the model with best TTFT for the prompt
func GetFastestModel(promptLength int) string {
	// Model selection based on prompt characteristics
	if promptLength < 20 {
		// Very short prompts - use smallest model
		return "smollm2:135m"
	} else if promptLength < 50 {
		// Short prompts - use Gemma 3 270M
		return "gemma3:270m"
	} else if promptLength < 100 {
		// Medium prompts
		return "qwen3:1.7b"
	} else {
		// Longer prompts - use model with better context handling
		return "qwen3:4b"
	}
}

// OptimizePrompt preprocesses prompt for faster inference
func OptimizePrompt(prompt string) string {
	// Trim whitespace
	prompt = strings.TrimSpace(prompt)
	
	// For very short prompts, add minimal context
	if len(prompt) < 10 && !strings.Contains(prompt, "?") {
		prompt += "?"
	}
	
	return prompt
}

var globalFastClient *FastOllamaClient

func initFastOllama() {
	ollamaURL := env("OLLAMA_URL", "http://127.0.0.1:11434")
	globalFastClient = NewFastOllamaClient(ollamaURL)
	
	// Preload models in parallel
	models := []string{"smollm2:135m", "gemma3:270m", "qwen3:1.7b", "qwen3:4b"}
	var wg sync.WaitGroup
	
	for _, model := range models {
		wg.Add(1)
		go func(m string) {
			defer wg.Done()
			if err := globalFastClient.PreloadModel(m); err != nil {
				log.Printf("Failed to preload %s: %v", m, err)
			}
		}(model)
	}
	
	// Don't wait - let models load in background
	go func() {
		wg.Wait()
		log.Println("✅ All models preloaded")
	}()
}