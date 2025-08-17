package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"
)

// OllamaManager handles model management and optimization
type OllamaManager struct {
	mu           sync.RWMutex
	client       *http.Client
	baseURL      string
	activeModels map[string]*ModelState
	warmupDone   map[string]bool
}

// ModelState tracks model-specific state
type ModelState struct {
	Name         string
	LastUsed     time.Time
	WarmupStatus bool
}

// NewOllamaManager creates a new Ollama manager
func NewOllamaManager(baseURL string) *OllamaManager {
	return &OllamaManager{
		client: &http.Client{
			Timeout: 30 * time.Second,
			Transport: &http.Transport{
				MaxIdleConns:        10,
				MaxIdleConnsPerHost: 10,
				IdleConnTimeout:     90 * time.Second,
			},
		},
		baseURL:      baseURL,
		activeModels: make(map[string]*ModelState),
		warmupDone:   make(map[string]bool),
	}
}

// WarmupModel preloads a model to reduce TTFT
func (om *OllamaManager) WarmupModel(model string) error {
	om.mu.Lock()
	if om.warmupDone[model] {
		om.mu.Unlock()
		return nil
	}
	om.mu.Unlock()

	log.Printf("🔥 Warming up model: %s", model)
	startTime := time.Now()

	// Send a simple prompt to load the model
	payload := map[string]interface{}{
		"model":    model,
		"messages": []map[string]string{{"role": "user", "content": "Hi"}},
		"stream":   false,
		"options": map[string]interface{}{
			"num_ctx":     2048,  // Smaller context for warmup
			"num_predict": 1,     // Only generate 1 token
			"temperature": 0.1,   // Low temperature for consistency
		},
	}

	body, _ := json.Marshal(payload)
	req, err := http.NewRequest("POST", om.baseURL+"/api/chat", bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := om.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("warmup failed: status %d", resp.StatusCode)
	}

	// Read response to complete the warmup
	var result map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&result)

	warmupTime := time.Since(startTime)
	log.Printf("✅ Model %s warmed up in %dms", model, warmupTime.Milliseconds())

	om.mu.Lock()
	om.warmupDone[model] = true
	om.activeModels[model] = &ModelState{
		Name:         model,
		LastUsed:     time.Now(),
		WarmupStatus: true,
	}
	om.mu.Unlock()

	return nil
}

// KeepAlive sends periodic requests to keep model in memory
func (om *OllamaManager) KeepAlive(model string) {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for range ticker.C {
		om.mu.RLock()
		state, exists := om.activeModels[model]
		om.mu.RUnlock()

		if !exists || time.Since(state.LastUsed) > 5*time.Minute {
			log.Printf("🛑 Stopping keep-alive for idle model: %s", model)
			return
		}

		// Send keep-alive request
		payload := map[string]interface{}{
			"model":     model,
			"keep_alive": "5m",
		}

		body, _ := json.Marshal(payload)
		req, _ := http.NewRequest("POST", om.baseURL+"/api/generate", bytes.NewReader(body))
		req.Header.Set("Content-Type", "application/json")

		resp, err := om.client.Do(req)
		if err == nil {
			resp.Body.Close()
		}
	}
}

// GetOptimizedSettings returns optimized settings for a model
func (om *OllamaManager) GetOptimizedSettings(model string) map[string]interface{} {
	// Model-specific optimizations
	settings := map[string]interface{}{
		"num_thread":     8,
		"num_batch":      512,
		"repeat_penalty": 1.1,
		"temperature":    0.7,
	}

	// Adjust based on model size
	switch model {
	case "qwen2.5:3b", "phi3:mini":
		settings["num_ctx"] = 2048
		settings["num_gpu"] = 1
		settings["num_thread"] = 4 // Use half CPUs for smaller models
	case "smollm2:135m":
		settings["num_ctx"] = 1024
		settings["num_thread"] = 4 // Minimal threads for tiny model
	case "gemma3:270m":
		settings["num_ctx"] = 1536
		settings["num_thread"] = 4 // Optimized for Gemma 3 270M
		settings["num_gpu"] = 1
	default:
		settings["num_ctx"] = 4096
	}

	return settings
}

// UpdateLastUsed updates the last used time for a model
func (om *OllamaManager) UpdateLastUsed(model string) {
	om.mu.Lock()
	defer om.mu.Unlock()
	
	if state, exists := om.activeModels[model]; exists {
		state.LastUsed = time.Now()
	}
}

var globalOllamaManager *OllamaManager

func initOllamaManager() {
	ollamaURL := env("OLLAMA_URL", "http://127.0.0.1:11434")
	globalOllamaManager = NewOllamaManager(ollamaURL)

	// Warmup default models
	go func() {
		models := []string{"smollm2:135m", "gemma3:270m", "qwen3:1.7b", "qwen3:4b"}
		for _, model := range models {
			if err := globalOllamaManager.WarmupModel(model); err != nil {
				log.Printf("Failed to warmup %s: %v", model, err)
			} else {
				// Start keep-alive for warmed up models
				go globalOllamaManager.KeepAlive(model)
			}
		}
	}()
}