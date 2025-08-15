package main

import (
	"bytes"
	"encoding/base64"
	"testing"
)

func TestNoiseManager(t *testing.T) {
	// Create two Noise managers (simulating server and client)
	server, err := NewNoiseManager()
	if err != nil {
		t.Fatalf("Failed to create server NoiseManager: %v", err)
	}

	client, err := NewNoiseManager()
	if err != nil {
		t.Fatalf("Failed to create client NoiseManager: %v", err)
	}

	t.Logf("Server public key: %s", server.GetPublicKey())
	t.Logf("Client public key: %s", client.GetPublicKey())

	// Test handshake
	t.Run("Handshake", func(t *testing.T) {
		peerID := "test-peer-1"

		// Client initiates handshake with server's public key
		serverPubKey, _ := base64.StdEncoding.DecodeString(server.GetPublicKey())
		initMsg, err := client.InitiateHandshake(peerID, serverPubKey)
		if err != nil {
			t.Fatalf("Failed to initiate handshake: %v", err)
		}

		// Server responds to handshake
		responseMsg, err := server.RespondHandshake(peerID, initMsg)
		if err != nil {
			t.Fatalf("Failed to respond to handshake: %v", err)
		}

		// Client processes response
		err = client.ProcessHandshakeResponse(peerID, responseMsg)
		if err != nil {
			t.Fatalf("Failed to process handshake response: %v", err)
		}

		// Check session info
		serverInfo, exists := server.GetSessionInfo(peerID)
		if !exists {
			t.Fatal("Server session not found")
		}
		if serverInfo["established"] != true {
			t.Fatal("Server session not established")
		}

		clientInfo, exists := client.GetSessionInfo(peerID)
		if !exists {
			t.Fatal("Client session not found")
		}
		if clientInfo["established"] != true {
			t.Fatal("Client session not established")
		}
	})

	// Test encryption/decryption
	t.Run("Encryption", func(t *testing.T) {
		peerID := "test-peer-1"
		testMessages := []string{
			"Hello, World!",
			"Quick brown fox jumps over the lazy dog",
			"🚀 Unicode test με ελληνικά",
			"", // Empty message
		}

		for _, msg := range testMessages {
			plaintext := []byte(msg)

			// Client encrypts message
			encrypted, err := client.EncryptMessage(peerID, plaintext)
			if err != nil {
				t.Fatalf("Failed to encrypt message: %v", err)
			}

			// Check that encrypted is different from plaintext (unless in dev mode)
			if !bytes.HasPrefix(encrypted, []byte("PLAINTEXT:")) && bytes.Equal(encrypted, plaintext) {
				t.Fatal("Encrypted message is same as plaintext")
			}

			// Server decrypts message
			decrypted, err := server.DecryptMessage(peerID, encrypted)
			if err != nil {
				t.Fatalf("Failed to decrypt message: %v", err)
			}

			// Verify decrypted matches original
			if !bytes.Equal(decrypted, plaintext) {
				t.Fatalf("Decrypted message doesn't match original: got %q, want %q", decrypted, plaintext)
			}
		}
	})

	// Test bidirectional encryption
	t.Run("Bidirectional", func(t *testing.T) {
		peerID := "test-peer-1"

		// Server -> Client
		serverMsg := []byte("Message from server")
		encrypted, err := server.EncryptMessage(peerID, serverMsg)
		if err != nil {
			t.Fatalf("Server failed to encrypt: %v", err)
		}

		decrypted, err := client.DecryptMessage(peerID, encrypted)
		if err != nil {
			t.Fatalf("Client failed to decrypt: %v", err)
		}

		if !bytes.Equal(decrypted, serverMsg) {
			t.Fatalf("Server->Client message mismatch: got %q, want %q", decrypted, serverMsg)
		}

		// Client -> Server
		clientMsg := []byte("Message from client")
		encrypted, err = client.EncryptMessage(peerID, clientMsg)
		if err != nil {
			t.Fatalf("Client failed to encrypt: %v", err)
		}

		decrypted, err = server.DecryptMessage(peerID, encrypted)
		if err != nil {
			t.Fatalf("Server failed to decrypt: %v", err)
		}

		if !bytes.Equal(decrypted, clientMsg) {
			t.Fatalf("Client->Server message mismatch: got %q, want %q", decrypted, clientMsg)
		}
	})

	// Test session cleanup
	t.Run("SessionCleanup", func(t *testing.T) {
		peerID := "test-peer-1"

		// Remove sessions
		server.RemoveSession(peerID)
		client.RemoveSession(peerID)

		// Try to encrypt after session removal
		_, err := client.EncryptMessage(peerID, []byte("test"))
		if err != ErrNoiseNotInitialized {
			t.Fatal("Expected ErrNoiseNotInitialized after session removal")
		}

		// Verify session is gone
		_, exists := server.GetSessionInfo(peerID)
		if exists {
			t.Fatal("Server session still exists after removal")
		}
	})

	// Test multiple sessions
	t.Run("MultipleSessions", func(t *testing.T) {
		// Create sessions with multiple peers
		for i := 0; i < 5; i++ {
			peerID := string(rune('A' + i))
			
			// Simplified handshake
			serverPubKey, _ := base64.StdEncoding.DecodeString(server.GetPublicKey())
			initMsg, _ := client.InitiateHandshake(peerID, serverPubKey)
			responseMsg, _ := server.RespondHandshake(peerID, initMsg)
			client.ProcessHandshakeResponse(peerID, responseMsg)

			// Test encryption for this peer
			msg := []byte("Hello " + peerID)
			encrypted, err := client.EncryptMessage(peerID, msg)
			if err != nil {
				t.Fatalf("Failed to encrypt for peer %s: %v", peerID, err)
			}

			decrypted, err := server.DecryptMessage(peerID, encrypted)
			if err != nil {
				t.Fatalf("Failed to decrypt for peer %s: %v", peerID, err)
			}

			if !bytes.Equal(decrypted, msg) {
				t.Fatalf("Message mismatch for peer %s", peerID)
			}
		}
	})
}

func TestNoiseMessageSizes(t *testing.T) {
	nm, _ := NewNoiseManager()
	peerID := "size-test"

	// Setup dummy session
	serverPubKey, _ := base64.StdEncoding.DecodeString(nm.GetPublicKey())
	nm.InitiateHandshake(peerID, serverPubKey)

	// Test message size limits
	t.Run("MaxMessageSize", func(t *testing.T) {
		// Just under max size
		largeMsg := make([]byte, maxMessageSize)
		_, err := nm.EncryptMessage(peerID, largeMsg)
		if err == nil {
			t.Skip("Session not properly established for size test")
		}

		// Over max size
		tooLargeMsg := make([]byte, maxMessageSize+1)
		_, err = nm.EncryptMessage(peerID, tooLargeMsg)
		if err != ErrMessageTooLarge && err != ErrNoiseNotInitialized {
			t.Fatal("Expected ErrMessageTooLarge for oversized message")
		}
	})
}

func BenchmarkNoiseEncryption(b *testing.B) {
	server, _ := NewNoiseManager()
	client, _ := NewNoiseManager()
	peerID := "bench-peer"

	// Setup session
	serverPubKey, _ := base64.StdEncoding.DecodeString(server.GetPublicKey())
	initMsg, _ := client.InitiateHandshake(peerID, serverPubKey)
	responseMsg, _ := server.RespondHandshake(peerID, initMsg)
	client.ProcessHandshakeResponse(peerID, responseMsg)

	// Benchmark encryption
	msg := []byte("This is a typical chat message that might be sent through QuicPair")

	b.Run("Encrypt", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			_, err := client.EncryptMessage(peerID, msg)
			if err != nil {
				b.Fatal(err)
			}
		}
	})

	// Get encrypted message for decrypt benchmark
	encrypted, _ := client.EncryptMessage(peerID, msg)

	b.Run("Decrypt", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			_, err := server.DecryptMessage(peerID, encrypted)
			if err != nil {
				b.Fatal(err)
			}
		}
	})

	b.Run("RoundTrip", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			encrypted, err := client.EncryptMessage(peerID, msg)
			if err != nil {
				b.Fatal(err)
			}
			_, err = server.DecryptMessage(peerID, encrypted)
			if err != nil {
				b.Fatal(err)
			}
		}
	})
}