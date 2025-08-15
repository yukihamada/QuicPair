package main

import (
	"crypto/rand"
	"encoding/base64"
	"log"
	"os"
	"sync"
)

// Simple Noise implementation for testing

const (
	keychainService = "com.quicpair.server"
	keychainAccount = "noise-private-key"
	noiseProtocol   = "Noise_IK_25519_ChaChaPoly_BLAKE2b"
	maxMessageSize  = 65535
)

type NoiseManager struct {
	mu           sync.RWMutex
	privateKey   []byte
	publicKey    []byte
	sessions     map[string]*NoiseSession
	devPlaintext bool
}

type NoiseSession struct {
	mu         sync.Mutex
	isComplete bool
}

func NewNoiseManager(devMode bool) (*NoiseManager, error) {
	nm := &NoiseManager{
		sessions:     make(map[string]*NoiseSession),
		devPlaintext: devMode && os.Getenv("DEV_ALLOW_PLAINTEXT") == "1",
	}

	// Generate a simple key for testing
	nm.privateKey = make([]byte, 32)
	nm.publicKey = make([]byte, 32)
	rand.Read(nm.privateKey)
	rand.Read(nm.publicKey)

	if nm.devPlaintext {
		log.Println("⚠️  WARNING: Plaintext mode enabled (dev only)")
	}

	return nm, nil
}

func (nm *NoiseManager) GetPublicKey() string {
	nm.mu.RLock()
	defer nm.mu.RUnlock()
	return base64.StdEncoding.EncodeToString(nm.publicKey)
}

func (nm *NoiseManager) StartSession(sessionID string, remotePublicKey []byte) (*NoiseSession, error) {
	nm.mu.Lock()
	defer nm.mu.Unlock()

	session := &NoiseSession{
		isComplete: true, // Simplified - always complete
	}
	nm.sessions[sessionID] = session
	return session, nil
}

func (nm *NoiseManager) HandleHandshake(sessionID string, message []byte) ([]byte, error) {
	nm.mu.Lock()
	defer nm.mu.Unlock()

	// Create session if doesn't exist
	if _, exists := nm.sessions[sessionID]; !exists {
		nm.sessions[sessionID] = &NoiseSession{isComplete: true}
	}

	// Return a simple response
	return []byte("HANDSHAKE_ACK"), nil
}

func (nm *NoiseManager) Encrypt(sessionID string, plaintext []byte) ([]byte, error) {
	if nm.devPlaintext {
		return plaintext, nil
	}
	// Simple XOR encryption for testing
	encrypted := make([]byte, len(plaintext))
	for i := range plaintext {
		encrypted[i] = plaintext[i] ^ 0xAA
	}
	return encrypted, nil
}

func (nm *NoiseManager) Decrypt(sessionID string, ciphertext []byte) ([]byte, error) {
	if nm.devPlaintext {
		return ciphertext, nil
	}
	// Simple XOR decryption for testing
	decrypted := make([]byte, len(ciphertext))
	for i := range ciphertext {
		decrypted[i] = ciphertext[i] ^ 0xAA
	}
	return decrypted, nil
}

func (nm *NoiseManager) CloseSession(sessionID string) {
	nm.mu.Lock()
	defer nm.mu.Unlock()
	delete(nm.sessions, sessionID)
	log.Printf("🔒 Closed Noise session %s", sessionID)
}

func (nm *NoiseManager) GetSessionStats() map[string]interface{} {
	nm.mu.RLock()
	defer nm.mu.RUnlock()

	return map[string]interface{}{
		"active_sessions": len(nm.sessions),
		"plaintext_mode":  nm.devPlaintext,
		"public_key":      nm.GetPublicKey(),
	}
}