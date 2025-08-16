# WebRTC Implementation Guide

## Overview

QuicPair uses WebRTC for ultra-low latency peer-to-peer communication between iPhone and Mac, enabling TTFT < 150ms across different networks.

## Architecture

### Components

1. **Signaling Server** (Go)
   - Endpoint: `http://localhost:8443/signaling/offer`
   - Handles SDP offer/answer exchange
   - Minimal involvement after connection established

2. **WebRTC DataChannel**
   - Channel name: `"llm"`
   - Reliable, ordered delivery
   - Carries JSON messages for chat

3. **NAT Traversal**
   - STUN: Google's public servers (always available)
   - TURN: Optional relay for restricted networks
   - ICE: Automatic best path selection

## Connection Flow

1. **iPhone scans QR code** containing signaling URL
2. **iPhone creates WebRTC offer** with local SDP
3. **Sends offer to signaling server** via HTTP POST
4. **Server creates answer** and returns it
5. **ICE negotiation** finds best connection path
6. **DataChannel opens** for bidirectional communication
7. **Noise handshake** establishes E2E encryption

## Message Protocol

### Client → Server
```json
{
  "op": "chat",
  "model": "qwen2.5:3b",
  "prompt": "Hello, how are you?",
  "stream": true
}
```

### Server → Client (Streaming)
```json
{"op": "delta", "content": "I'm"}
{"op": "delta", "content": " doing"}
{"op": "delta", "content": " well!"}
{"op": "done"}
```

## NAT Traversal Configuration

### STUN (Always Available)
- `stun:stun.l.google.com:19302`
- `stun:stun1.l.google.com:19302`
- `stun:stun2.l.google.com:19302`

### TURN (Optional)
Configure via environment variables:
```bash
export TURN_URLS='turn:your-server.com:3478'
export TURN_USER='username'
export TURN_PASS='password'
```

Or in iOS app settings.

## Performance Optimizations

1. **Connection Pooling**: Reuse peer connections when possible
2. **ICE Trickling**: Disabled for faster connection setup
3. **Gathering Policy**: Continual gathering for quick reconnects
4. **DataChannel Config**: Reliable, ordered for chat consistency

## Testing

### Local Network (Direct P2P)
```bash
./scripts/test_webrtc_connection.sh
```

### Cross-Network (Via TURN)
```bash
export TURN_URLS='turn:relay.example.com:3478'
export TURN_USER='test'
export TURN_PASS='test123'
./scripts/test_webrtc_connection.sh
```

## Troubleshooting

### Connection Fails
1. Check firewall allows UDP traffic
2. Verify STUN server accessibility: `dig stun.l.google.com`
3. Enable TURN if behind symmetric NAT

### High Latency
1. Check if using TURN relay (should be direct when possible)
2. Verify no VPN interfering with local connections
3. Use `chrome://webrtc-internals` for debugging

### iOS Build Issues
1. Ensure WebRTC framework added via CocoaPods or SPM
2. Set minimum iOS version to 16.0
3. Disable bitcode in build settings

## Security Considerations

1. **Signaling**: Use HTTPS in production
2. **TURN Auth**: Use time-limited credentials
3. **Noise Protocol**: Always verify public keys
4. **Local Mode**: Restrict to local IPs when enabled