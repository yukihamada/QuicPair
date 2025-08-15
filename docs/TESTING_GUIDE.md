# QuicPair Testing Guide - Mac to iPhone P2P Connection

## Overview
This guide provides comprehensive instructions for testing P2P connections between Mac and iPhone apps, focusing on WebRTC establishment and TTFT (Time To First Token) performance measurement.

## Prerequisites

### Required Software
- **Mac**: macOS 12.0+ with Xcode installed
- **iPhone**: iOS 15.0+ with QuicPair app installed
- **Ollama**: Running locally with `llama3.1:8b-instruct-q4_K_M` model
- **Tools**: `go`, `swift`, `curl`, `jq`, `nc` (netcat)

### Optional Tools
- `qrencode`: For generating QR code images (`brew install qrencode`)
- `wireshark`: For packet analysis and E2E encryption verification

## Testing Procedures

### 1. Basic P2P Connection Test

**Purpose**: Verify WebRTC connection establishment and E2E encryption

```bash
# Run the comprehensive test script
./scripts/test_mac_iphone_p2p.sh

# The script will:
# 1. Check prerequisites
# 2. Build and start the server
# 3. Generate QR code for iPhone connection
# 4. Monitor connections and TTFT
# 5. Calculate performance statistics
```

**Manual Steps**:
1. When QR code appears on Mac, open QuicPair on iPhone
2. Tap "Scan QR Code" 
3. Point camera at QR code on Mac screen
4. Wait for "Connected" status
5. Send test messages from iPhone when prompted

### 2. Real-time TTFT Monitoring

**Purpose**: Monitor TTFT performance in real-time during testing

```bash
# In Terminal 1: Start the server
cd server
go run . > server.log 2>&1

# In Terminal 2: Start real-time monitor
./scripts/measure_ttft_realtime.sh

# The monitor will show:
# - Live TTFT measurements
# - Running statistics (P50, P90, etc.)
# - Performance distribution chart
# - Connection events
```

### 3. Automated TTFT Testing

**Purpose**: Run automated TTFT measurements without manual intervention

```bash
# Basic test (10 iterations)
./scripts/measure_ttft.sh p2p 10

# TURN relay test (if configured)
./scripts/measure_ttft.sh turn 10

# Using test automation helper
./scripts/test_automation_helper.swift http://localhost:8443 basic 20
```

### 4. E2E Encryption Verification

**Purpose**: Verify Noise IK encryption is working properly

```bash
# Run E2E encryption tests
./scripts/test_e2e_encryption.sh

# Manual verification:
# 1. Start Wireshark capture on port 8443
# 2. Establish connection between Mac and iPhone
# 3. Send messages
# 4. Verify DataChannel payloads are encrypted
# 5. Check for Noise handshake completion in logs
```

## Performance Targets

### TTFT Requirements
- **P50**: < 150ms ✓
- **P90**: < 250ms ✓
- **P95**: < 400ms (best effort)

### Connection Establishment
- Initial connection: < 2s
- Reconnection (ICE restart): < 500ms

## Test Scenarios

### Scenario 1: Cold Start Performance
1. Ensure Ollama model is loaded but not warmed up
2. Start fresh server instance
3. Connect iPhone for first time
4. Measure first message TTFT (expect higher)
5. Measure subsequent messages (should meet targets)

### Scenario 2: Sustained Load
1. Establish connection
2. Send messages continuously for 5 minutes
3. Monitor for TTFT degradation
4. Verify no memory leaks or performance drops

### Scenario 3: Network Switching
1. Connect over WiFi
2. Send test messages, record TTFT
3. Switch iPhone to cellular (disable WiFi)
4. Verify connection maintains or quickly reestablishes
5. Compare TTFT before/after switch

### Scenario 4: Background Behavior
1. Establish connection
2. Put iPhone app in background
3. Wait 30 seconds
4. Bring app to foreground
5. Verify connection state and measure recovery time

## Interpreting Results

### TTFT Results JSON Format
```json
{
  "mode": "p2p",
  "iterations": 20,
  "metrics": {
    "min_ms": 89,
    "max_ms": 187,
    "avg_ms": 124.5,
    "p50_ms": 118,
    "p90_ms": 165
  },
  "targets": {
    "p50_target_met": true,
    "p90_target_met": true
  }
}
```

### Server Logs
Key log entries to monitor:
- `DataChannel opened` - WebRTC connection established
- `E2E encryption established` - Noise handshake completed
- `TTFT: XXXms` - Time to first token measurement
- `ICE connection state: connected` - Network path established

### Common Issues and Solutions

#### High TTFT (>250ms)
- Check Ollama is warmed up: `curl http://localhost:11434/api/generate -d '{"model":"llama3.1:8b-instruct-q4_K_M","prompt":"test"}'`
- Verify no CPU throttling: `sudo pmset -g thermlog`
- Check network latency: `ping -c 10 iPhone-IP`

#### Connection Failures
- Verify firewall allows port 8443: `sudo pfctl -s rules`
- Check both devices on same network: `arp -a`
- Confirm Strict Local Mode not blocking: `DISABLE_STRICT_LOCAL=1 ./server`

#### E2E Encryption Issues
- Check Noise keys generated: `curl http://localhost:8443/noise/pubkey`
- Verify no `DEV_ALLOW_PLAINTEXT=1` in production
- Look for handshake errors in server logs

## Test Reporting

### PR Test Results Template
```markdown
## TTFT Test Results

**Test Environment**:
- Mac: [Model, macOS version]
- iPhone: [Model, iOS version]  
- Network: [WiFi/Cellular, rough latency]
- Ollama Model: llama3.1:8b-instruct-q4_K_M

**P2P Results**:
- Iterations: 20
- P50: XXXms ✓
- P90: XXXms ✓

**TURN Results** (if applicable):
- Iterations: 20  
- P50: XXXms ✓
- P90: XXXms ✓

**E2E Encryption**: ✓ Verified with Wireshark

[Attach ttft_results.json]
```

## Continuous Testing

### Daily Smoke Test
```bash
#!/bin/bash
# Add to cron or launchd for daily runs
./scripts/measure_ttft.sh p2p 10
./scripts/test_e2e_encryption.sh
# Email or post results to monitoring system
```

### Performance Regression Detection
- Run tests before/after changes
- Compare P50/P90 values
- Flag if degradation >10%

## Advanced Testing

### Custom Test Prompts
Edit `scripts/measure_ttft.sh` or create custom test:
```bash
PROMPTS=(
  "Short response"
  "Medium length explanation about something"
  "Complex multi-part question requiring thought"
)
```

### Network Simulation
Use Network Link Conditioner (Mac) or similar tools:
- 3G: 100ms latency, 1Mbps
- LTE: 50ms latency, 10Mbps  
- WiFi: 5ms latency, 100Mbps

### Load Testing
Run multiple iPhone connections simultaneously:
1. Use multiple devices or simulators
2. Monitor server CPU/memory
3. Check TTFT remains within targets

## Security Testing

### Verify Strict Local Mode
```bash
# Should succeed (local)
curl http://localhost:8443/healthz

# Should fail (external IP)
curl http://[external-ip]:8443/healthz

# With Strict Local disabled (testing only)
DISABLE_STRICT_LOCAL=1 ./server
```

### Noise Key Rotation
Test key persistence and rotation:
1. Note initial public key
2. Restart server
3. Verify key persists
4. Delete key file, restart
5. Verify new key generated

## Troubleshooting

### Enable Debug Logging
```bash
# Server debug mode
DEBUG=1 ./server

# Verbose WebRTC logs
PION_LOG_LEVEL=debug ./server
```

### Check Port Availability
```bash
lsof -i :8443
netstat -an | grep 8443
```

### Verify Ollama Performance
```bash
# Benchmark Ollama directly
time curl http://localhost:11434/api/generate \
  -d '{"model":"llama3.1:8b-instruct-q4_K_M","prompt":"test","stream":false}'
```

## Summary

Regular testing ensures QuicPair maintains its performance and security goals. Focus on:
1. **TTFT targets** (P50 <150ms, P90 <250ms)
2. **E2E encryption** always active
3. **Strict Local Mode** functioning
4. **Connection reliability** across network changes

Document all test results and include in PRs for traceability.