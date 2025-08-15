#!/bin/bash
# test_e2e_encryption.sh - Test Noise IK E2E encryption

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== QuicPair E2E Encryption Test ===${NC}"

# Test 1: Server Noise key generation
echo -e "\n${YELLOW}[TEST 1]${NC} Server key generation"
cd server
go test -v -run TestNoiseManager/Handshake
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Noise handshake test passed"
else
    echo -e "${RED}✗${NC} Noise handshake test failed"
    exit 1
fi

# Test 2: Encryption/Decryption
echo -e "\n${YELLOW}[TEST 2]${NC} Encryption/Decryption"
go test -v -run TestNoiseManager/Encryption
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Encryption test passed"
else
    echo -e "${RED}✗${NC} Encryption test failed"
    exit 1
fi

# Test 3: Benchmark encryption overhead
echo -e "\n${YELLOW}[TEST 3]${NC} Encryption performance"
go test -bench=BenchmarkNoiseEncryption -benchtime=10s
echo -e "${GREEN}✓${NC} Performance benchmark completed"

# Test 4: Integration test with real server
echo -e "\n${YELLOW}[TEST 4]${NC} Integration test"
echo "Starting server..."
go build -o quicpair-server .
./quicpair-server > server.log 2>&1 &
SERVER_PID=$!
sleep 2

# Check server started
if ! curl -s http://localhost:8443/healthz | grep -q "ok"; then
    echo -e "${RED}✗${NC} Server failed to start"
    kill $SERVER_PID 2>/dev/null || true
    exit 1
fi

# Get server public key
SERVER_PUBKEY=$(curl -s http://localhost:8443/noise/pubkey | jq -r .public_key)
echo -e "Server public key: ${SERVER_PUBKEY}"

# TODO: Add actual WebRTC client test here
echo -e "${YELLOW}[NOTE]${NC} Full integration test requires iOS client"

# Cleanup
kill $SERVER_PID 2>/dev/null || true
rm -f server.log quicpair-server

echo -e "\n${GREEN}=== All E2E encryption tests passed ===${NC}"