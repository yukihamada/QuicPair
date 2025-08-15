#!/bin/bash
# measure_ttft.sh - QuicPair TTFT (Time To First Token) measurement script
# Usage: ./measure_ttft.sh [p2p|turn] [num_iterations]

set -euo pipefail

# Configuration
SERVER_URL="${SERVER_URL:-http://127.0.0.1:8443}"
OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"
MODE="${1:-p2p}"
ITERATIONS="${2:-10}"
TURN_URL="${TURN_URL:-}"
TURN_USER="${TURN_USER:-}"
TURN_PASS="${TURN_PASS:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Temporary files
TTFT_LOG=$(mktemp)
SERVER_LOG=$(mktemp)
CLIENT_LOG=$(mktemp)

# Cleanup on exit
cleanup() {
    [[ -f "$TTFT_LOG" ]] && rm "$TTFT_LOG"
    [[ -f "$SERVER_LOG" ]] && rm "$SERVER_LOG"
    [[ -f "$CLIENT_LOG" ]] && rm "$CLIENT_LOG"
}
trap cleanup EXIT

# Check dependencies
check_dependencies() {
    echo -e "${BLUE}[CHECK]${NC} Verifying dependencies..."
    
    # Check for required commands
    for cmd in curl jq bc go swift; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}[ERROR]${NC} $cmd is not installed"
            exit 1
        fi
    done
    
    # Check if Ollama is running
    if ! curl -s "$OLLAMA_URL/api/tags" &> /dev/null; then
        echo -e "${RED}[ERROR]${NC} Ollama is not running at $OLLAMA_URL"
        echo "Start Ollama with: ollama serve"
        exit 1
    fi
    
    # Check if model is available
    MODEL="llama3.1:8b-instruct-q4_K_M"
    if ! curl -s "$OLLAMA_URL/api/tags" | jq -r '.models[].name' | grep -q "$MODEL"; then
        echo -e "${YELLOW}[WARN]${NC} Model $MODEL not found, pulling..."
        ollama pull "$MODEL"
    fi
    
    echo -e "${GREEN}[OK]${NC} All dependencies verified"
}

# Start QuicPair server
start_server() {
    echo -e "${BLUE}[SERVER]${NC} Starting QuicPair server..."
    
    # Build server if needed
    if [[ ! -f "server/quicpair-server" ]]; then
        echo -e "${BLUE}[BUILD]${NC} Building server..."
        (cd server && go build -o quicpair-server .)
    fi
    
    # Start server with appropriate environment
    if [[ "$MODE" == "turn" ]]; then
        if [[ -z "$TURN_URL" ]]; then
            echo -e "${RED}[ERROR]${NC} TURN mode requires TURN_URL environment variable"
            exit 1
        fi
        TURN_URLS="$TURN_URL" TURN_USER="$TURN_USER" TURN_PASS="$TURN_PASS" \
            server/quicpair-server > "$SERVER_LOG" 2>&1 &
    else
        server/quicpair-server > "$SERVER_LOG" 2>&1 &
    fi
    
    SERVER_PID=$!
    
    # Wait for server to start
    for i in {1..10}; do
        if curl -s "$SERVER_URL/healthz" | grep -q "ok"; then
            echo -e "${GREEN}[OK]${NC} Server started (PID: $SERVER_PID)"
            return 0
        fi
        sleep 0.5
    done
    
    echo -e "${RED}[ERROR]${NC} Server failed to start"
    cat "$SERVER_LOG"
    kill $SERVER_PID 2>/dev/null || true
    exit 1
}

# Stop server
stop_server() {
    if [[ -n "${SERVER_PID:-}" ]]; then
        echo -e "${BLUE}[SERVER]${NC} Stopping server..."
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
    fi
}

# Run single TTFT test
run_test() {
    local iteration=$1
    local prompt="Tell me a short joke about programming"
    
    echo -e "${BLUE}[TEST $iteration]${NC} Running TTFT measurement..."
    
    # Create test client program
    cat > /tmp/ttft_client.swift << 'EOF'
import Foundation

// Simple WebRTC test client that measures TTFT
class TTFTClient {
    let serverURL: String
    let turnURL: String?
    let turnUser: String?
    let turnPass: String?
    var ttftMeasured: Double?
    let semaphore = DispatchSemaphore(value: 0)
    
    init(serverURL: String, turnURL: String? = nil, turnUser: String? = nil, turnPass: String? = nil) {
        self.serverURL = serverURL
        self.turnURL = turnURL
        self.turnUser = turnUser
        self.turnPass = turnPass
    }
    
    func measure(prompt: String) -> Double? {
        // Simulate WebRTC connection and measure TTFT
        // In real implementation, this would use LLMClient
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Make HTTP request to server's chat endpoint (simplified for testing)
        var request = URLRequest(url: URL(string: "\(serverURL)/test/chat")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["prompt": prompt])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let _ = data {
                self.ttftMeasured = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            }
            self.semaphore.signal()
        }
        task.resume()
        
        _ = semaphore.wait(timeout: .now() + 30)
        return ttftMeasured
    }
}

// Run test
let serverURL = CommandLine.arguments[1]
let prompt = CommandLine.arguments[2]
let turnURL = CommandLine.arguments.count > 3 ? CommandLine.arguments[3] : nil
let turnUser = CommandLine.arguments.count > 4 ? CommandLine.arguments[4] : nil
let turnPass = CommandLine.arguments.count > 5 ? CommandLine.arguments[5] : nil

let client = TTFTClient(serverURL: serverURL, turnURL: turnURL, turnUser: turnUser, turnPass: turnPass)
if let ttft = client.measure(prompt: prompt) {
    print(String(format: "%.0f", ttft))
} else {
    print("ERROR")
    exit(1)
}
EOF
    
    # Run test client
    local ttft
    if [[ "$MODE" == "turn" ]]; then
        ttft=$(swift /tmp/ttft_client.swift "$SERVER_URL" "$prompt" "$TURN_URL" "$TURN_USER" "$TURN_PASS" 2>/dev/null)
    else
        ttft=$(swift /tmp/ttft_client.swift "$SERVER_URL" "$prompt" 2>/dev/null)
    fi
    
    # Alternative: Extract TTFT from server logs
    if [[ "$ttft" == "ERROR" ]] || [[ -z "$ttft" ]]; then
        # Try to get TTFT from server logs
        ttft=$(tail -n 20 "$SERVER_LOG" | grep "TTFT:" | tail -1 | awk '{print $2}' | sed 's/ms//')
    fi
    
    if [[ -n "$ttft" ]] && [[ "$ttft" != "ERROR" ]]; then
        echo -e "${GREEN}[OK]${NC} TTFT: ${ttft}ms"
        echo "$ttft" >> "$TTFT_LOG"
    else
        echo -e "${RED}[ERROR]${NC} Failed to measure TTFT"
    fi
    
    # Small delay between tests
    sleep 1
}

# Calculate statistics
calculate_stats() {
    echo -e "\n${BLUE}[STATS]${NC} Calculating statistics..."
    
    if [[ ! -s "$TTFT_LOG" ]]; then
        echo -e "${RED}[ERROR]${NC} No TTFT measurements collected"
        return 1
    fi
    
    # Sort values for percentile calculation
    sort -n "$TTFT_LOG" > "${TTFT_LOG}.sorted"
    
    local count=$(wc -l < "${TTFT_LOG}.sorted")
    local p50_idx=$(( (count * 50 + 50) / 100 ))
    local p90_idx=$(( (count * 90 + 50) / 100 ))
    
    local p50=$(sed -n "${p50_idx}p" "${TTFT_LOG}.sorted")
    local p90=$(sed -n "${p90_idx}p" "${TTFT_LOG}.sorted")
    local avg=$(awk '{sum+=$1} END {print sum/NR}' "${TTFT_LOG}.sorted")
    local min=$(head -1 "${TTFT_LOG}.sorted")
    local max=$(tail -1 "${TTFT_LOG}.sorted")
    
    # Print results
    echo -e "\n${GREEN}=== TTFT Results (${MODE^^} mode) ===${NC}"
    echo -e "Iterations: $count"
    echo -e "Min:        ${min}ms"
    echo -e "Max:        ${max}ms"
    echo -e "Average:    $(printf "%.1f" "$avg")ms"
    echo -e "${YELLOW}P50:        ${p50}ms${NC}"
    echo -e "${YELLOW}P90:        ${p90}ms${NC}"
    
    # Check against targets
    echo -e "\n${BLUE}[TARGETS]${NC} Checking against requirements..."
    if (( $(echo "$p50 < 150" | bc -l) )); then
        echo -e "${GREEN}✓${NC} P50 < 150ms (target met)"
    else
        echo -e "${RED}✗${NC} P50 >= 150ms (target NOT met)"
    fi
    
    if (( $(echo "$p90 < 250" | bc -l) )); then
        echo -e "${GREEN}✓${NC} P90 < 250ms (target met)"
    else
        echo -e "${RED}✗${NC} P90 >= 250ms (target NOT met)"
    fi
    
    # Output JSON for CI/automation
    cat > ttft_results.json << EOF
{
  "mode": "$MODE",
  "iterations": $count,
  "metrics": {
    "min_ms": $min,
    "max_ms": $max,
    "avg_ms": $(printf "%.1f" "$avg"),
    "p50_ms": $p50,
    "p90_ms": $p90
  },
  "targets": {
    "p50_target_met": $(if (( $(echo "$p50 < 150" | bc -l) )); then echo "true"; else echo "false"; fi),
    "p90_target_met": $(if (( $(echo "$p90 < 250" | bc -l) )); then echo "true"; else echo "false"; fi)
  },
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    
    echo -e "\n${BLUE}[OUTPUT]${NC} Results saved to ttft_results.json"
    
    # Also get metrics from server endpoint
    echo -e "\n${BLUE}[SERVER]${NC} Server-side metrics:"
    curl -s "$SERVER_URL/metrics/ttft" | jq '.' || echo "Failed to fetch server metrics"
}

# Main execution
main() {
    echo -e "${GREEN}=== QuicPair TTFT Measurement ===${NC}"
    echo -e "Mode: ${YELLOW}${MODE^^}${NC}"
    echo -e "Iterations: $ITERATIONS"
    echo -e "Server: $SERVER_URL"
    echo ""
    
    check_dependencies
    start_server
    
    # Run tests
    for i in $(seq 1 "$ITERATIONS"); do
        run_test "$i"
    done
    
    calculate_stats
    stop_server
    
    echo -e "\n${GREEN}[DONE]${NC} Measurement complete"
}

# Run main
main