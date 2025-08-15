#!/bin/bash
# test_mac_iphone_p2p.sh - Comprehensive P2P testing between Mac and iPhone
# Tests WebRTC connection establishment and TTFT performance

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SERVER_PORT="${SERVER_PORT:-8443}"
OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"
TEST_ITERATIONS="${TEST_ITERATIONS:-20}"
LOG_DIR="${PROJECT_ROOT}/test-logs/$(date +%Y%m%d_%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Create log directory
mkdir -p "$LOG_DIR"

# Logging functions
log() {
    echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} $1" | tee -a "$LOG_DIR/test.log"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_DIR/test.log"
}

error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_DIR/test.log"
}

warn() {
    echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_DIR/test.log"
}

# Get local IP address
get_local_ip() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - get IP from active interface
        ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1
    else
        # Linux
        hostname -I | awk '{print $1}'
    fi
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check for required tools
    local missing_tools=()
    for tool in go swift curl jq nc; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        error "Missing required tools: ${missing_tools[*]}"
        echo "Please install missing tools and try again."
        exit 1
    fi
    
    # Check if Ollama is running
    if ! curl -s "$OLLAMA_URL/api/tags" &> /dev/null; then
        error "Ollama is not running at $OLLAMA_URL"
        echo "Start Ollama with: ollama serve"
        exit 1
    fi
    
    # Check if model is available
    local model="llama3.1:8b-instruct-q4_K_M"
    if ! curl -s "$OLLAMA_URL/api/tags" | jq -r '.models[].name' | grep -q "$model"; then
        warn "Model $model not found, pulling..."
        ollama pull "$model"
    fi
    
    success "All prerequisites satisfied"
}

# Build server if needed
build_server() {
    log "Building QuicPair server..."
    
    cd "$PROJECT_ROOT/server"
    if go build -o quicpair-server . 2>&1 | tee "$LOG_DIR/server-build.log"; then
        success "Server built successfully"
    else
        error "Server build failed"
        exit 1
    fi
    cd "$PROJECT_ROOT"
}

# Start server
start_server() {
    log "Starting QuicPair server..."
    
    # Kill any existing server
    pkill -f quicpair-server 2>/dev/null || true
    sleep 1
    
    # Start server with logging
    cd "$PROJECT_ROOT/server"
    ./quicpair-server > "$LOG_DIR/server.log" 2>&1 &
    local server_pid=$!
    cd "$PROJECT_ROOT"
    
    # Wait for server to start
    local max_attempts=20
    local attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if curl -s "http://127.0.0.1:$SERVER_PORT/healthz" | grep -q "ok"; then
            success "Server started (PID: $server_pid)"
            echo $server_pid > "$LOG_DIR/server.pid"
            
            # Get server info
            local local_ip=$(get_local_ip)
            log "Server accessible at: $local_ip:$SERVER_PORT"
            
            # Get Noise public key
            local pubkey=$(curl -s "http://127.0.0.1:$SERVER_PORT/noise/pubkey" | jq -r .public_key)
            log "Server public key: $pubkey"
            
            return 0
        fi
        sleep 0.5
        ((attempt++))
    done
    
    error "Server failed to start"
    tail -20 "$LOG_DIR/server.log"
    kill $server_pid 2>/dev/null || true
    exit 1
}

# Generate QR code data
generate_qr_data() {
    local local_ip=$(get_local_ip)
    local pubkey=$(curl -s "http://127.0.0.1:$SERVER_PORT/noise/pubkey" | jq -r .public_key)
    local hostname=$(hostname -s)
    
    local qr_data=$(jq -n \
        --arg url "ws://$local_ip:$SERVER_PORT" \
        --arg key "$pubkey" \
        --arg name "$hostname" \
        --arg ver "1.0" \
        '{serverURL: $url, publicKey: $key, deviceName: $name, version: $ver}')
    
    echo "$qr_data" > "$LOG_DIR/qr_data.json"
    log "QR data saved to: $LOG_DIR/qr_data.json"
    
    # Generate QR code image if qrencode is available
    if command -v qrencode &> /dev/null; then
        echo "$qr_data" | qrencode -o "$LOG_DIR/qr_code.png" -s 10
        success "QR code image saved to: $LOG_DIR/qr_code.png"
        
        # Open QR code on Mac
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open "$LOG_DIR/qr_code.png"
        fi
    else
        warn "qrencode not installed, QR image not generated"
        echo "Install with: brew install qrencode"
    fi
    
    echo "$qr_data"
}

# Monitor WebRTC connections
monitor_connections() {
    log "Monitoring for WebRTC connections..."
    
    # Start monitoring server logs for connections
    tail -f "$LOG_DIR/server.log" | while read -r line; do
        if echo "$line" | grep -q "DataChannel opened"; then
            success "DataChannel established!"
            echo "$line" >> "$LOG_DIR/connections.log"
        elif echo "$line" | grep -q "E2E encryption established"; then
            success "E2E encryption established!"
            echo "$line" >> "$LOG_DIR/connections.log"
        elif echo "$line" | grep -q "TTFT:"; then
            local ttft=$(echo "$line" | grep -oE "TTFT: [0-9]+ms" | awk '{print $2}')
            echo "$ttft" | sed 's/ms//' >> "$LOG_DIR/ttft_measurements.txt"
            log "TTFT measurement: $ttft"
        fi
    done &
    
    echo $! > "$LOG_DIR/monitor.pid"
}

# Test TTFT with simulated messages
test_ttft() {
    log "Starting TTFT measurements..."
    
    # Wait for connection
    log "Waiting for iPhone connection..."
    echo -e "\n${MAGENTA}=== ACTION REQUIRED ===${NC}"
    echo "1. Open QuicPair app on iPhone"
    echo "2. Tap 'Scan QR Code'"
    echo "3. Scan the QR code displayed on Mac"
    echo "4. Wait for connection to establish"
    echo -e "\nPress ENTER when connected..."
    read -r
    
    # Check if connection is established
    if ! grep -q "DataChannel opened" "$LOG_DIR/server.log"; then
        error "No WebRTC connection detected"
        return 1
    fi
    
    success "Connection established, starting TTFT tests"
    
    # Run TTFT measurements
    log "Running $TEST_ITERATIONS TTFT measurements..."
    
    for i in $(seq 1 "$TEST_ITERATIONS"); do
        echo -e "\n${BLUE}[Test $i/$TEST_ITERATIONS]${NC}"
        echo "Send a message from iPhone (e.g., 'Tell me a joke')"
        echo "Press ENTER after message is sent..."
        read -r
        
        # Extract latest TTFT from server log
        local ttft=$(tail -100 "$LOG_DIR/server.log" | grep "TTFT:" | tail -1 | awk '{print $2}' | sed 's/ms//')
        if [[ -n "$ttft" ]]; then
            success "TTFT: ${ttft}ms"
        else
            warn "TTFT not captured for this test"
        fi
        
        sleep 2
    done
}

# Calculate and display statistics
calculate_stats() {
    log "Calculating TTFT statistics..."
    
    if [[ ! -f "$LOG_DIR/ttft_measurements.txt" ]] || [[ ! -s "$LOG_DIR/ttft_measurements.txt" ]]; then
        error "No TTFT measurements found"
        return 1
    fi
    
    # Sort measurements
    sort -n "$LOG_DIR/ttft_measurements.txt" > "$LOG_DIR/ttft_sorted.txt"
    
    # Calculate statistics
    local count=$(wc -l < "$LOG_DIR/ttft_sorted.txt")
    local p50_idx=$(( (count * 50 + 50) / 100 ))
    local p90_idx=$(( (count * 90 + 50) / 100 ))
    local p95_idx=$(( (count * 95 + 50) / 100 ))
    
    local p50=$(sed -n "${p50_idx}p" "$LOG_DIR/ttft_sorted.txt")
    local p90=$(sed -n "${p90_idx}p" "$LOG_DIR/ttft_sorted.txt")
    local p95=$(sed -n "${p95_idx}p" "$LOG_DIR/ttft_sorted.txt")
    local avg=$(awk '{sum+=$1} END {print sum/NR}' "$LOG_DIR/ttft_sorted.txt")
    local min=$(head -1 "$LOG_DIR/ttft_sorted.txt")
    local max=$(tail -1 "$LOG_DIR/ttft_sorted.txt")
    
    # Display results
    echo -e "\n${GREEN}========== TTFT Test Results ==========${NC}"
    echo "Test Date:     $(date)"
    echo "Measurements:  $count"
    echo "Connection:    Mac → iPhone (P2P)"
    echo ""
    echo "TTFT Statistics:"
    echo "  Min:         ${min}ms"
    echo "  Max:         ${max}ms"
    echo "  Average:     $(printf "%.1f" "$avg")ms"
    echo -e "  ${YELLOW}P50:         ${p50}ms${NC}"
    echo -e "  ${YELLOW}P90:         ${p90}ms${NC}"
    echo "  P95:         ${p95}ms"
    echo ""
    
    # Check against targets
    echo "Performance Targets:"
    if (( $(echo "$p50 < 150" | bc -l) )); then
        success "P50 < 150ms ✓ (Target Met)"
    else
        error "P50 >= 150ms ✗ (Target NOT Met)"
    fi
    
    if (( $(echo "$p90 < 250" | bc -l) )); then
        success "P90 < 250ms ✓ (Target Met)"
    else
        error "P90 >= 250ms ✗ (Target NOT Met)"
    fi
    
    # Save results as JSON
    cat > "$LOG_DIR/test_results.json" << EOF
{
  "test_type": "mac_iphone_p2p",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "measurements": $count,
  "metrics": {
    "min_ms": $min,
    "max_ms": $max,
    "avg_ms": $(printf "%.1f" "$avg"),
    "p50_ms": $p50,
    "p90_ms": $p90,
    "p95_ms": $p95
  },
  "targets": {
    "p50_target_met": $(if (( $(echo "$p50 < 150" | bc -l) )); then echo "true"; else echo "false"; fi),
    "p90_target_met": $(if (( $(echo "$p90 < 250" | bc -l) )); then echo "true"; else echo "false"; fi)
  },
  "environment": {
    "mac_ip": "$(get_local_ip)",
    "server_port": $SERVER_PORT,
    "ollama_url": "$OLLAMA_URL"
  }
}
EOF
    
    success "Results saved to: $LOG_DIR/test_results.json"
    echo -e "${GREEN}=======================================${NC}"
}

# Cleanup function
cleanup() {
    log "Cleaning up..."
    
    # Stop monitor
    if [[ -f "$LOG_DIR/monitor.pid" ]]; then
        kill $(cat "$LOG_DIR/monitor.pid") 2>/dev/null || true
    fi
    
    # Stop server
    if [[ -f "$LOG_DIR/server.pid" ]]; then
        kill $(cat "$LOG_DIR/server.pid") 2>/dev/null || true
    fi
    
    # Kill any remaining processes
    pkill -f quicpair-server 2>/dev/null || true
    
    log "Test logs saved in: $LOG_DIR"
}

# Set trap for cleanup
trap cleanup EXIT

# Main test flow
main() {
    echo -e "${GREEN}=== QuicPair Mac-iPhone P2P Test ===${NC}"
    echo "Test logs will be saved to: $LOG_DIR"
    echo ""
    
    check_prerequisites
    build_server
    start_server
    
    echo -e "\n${MAGENTA}=== Connection Setup ===${NC}"
    local qr_data=$(generate_qr_data)
    echo -e "\nQR Code Data:"
    echo "$qr_data" | jq .
    
    monitor_connections
    test_ttft
    calculate_stats
    
    echo -e "\n${GREEN}=== Test Complete ===${NC}"
    echo "Full logs available at: $LOG_DIR"
}

# Run main
main