#!/bin/bash
# measure_ttft_realtime.sh - Real-time TTFT monitoring for Mac-iPhone connections
# Monitors server logs and provides live TTFT statistics

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SERVER_LOG="${SERVER_LOG:-$PROJECT_ROOT/server/server.log}"
STATS_INTERVAL="${STATS_INTERVAL:-10}"  # Show stats every N measurements

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Arrays to store measurements
declare -a ttft_values=()
declare -a timestamps=()

# Function to calculate percentile
percentile() {
    local p=$1
    local sorted=("${ttft_values[@]}")
    IFS=$'\n' sorted=($(sort -n <<<"${sorted[*]}"))
    local count=${#sorted[@]}
    local index=$(( (count * p + 50) / 100 - 1 ))
    [[ $index -lt 0 ]] && index=0
    echo "${sorted[$index]}"
}

# Function to display live stats
display_stats() {
    clear
    echo -e "${GREEN}=== QuicPair TTFT Real-time Monitor ===${NC}"
    echo -e "Monitoring: ${YELLOW}$SERVER_LOG${NC}"
    echo -e "Time: $(date +%H:%M:%S)\n"
    
    if [ ${#ttft_values[@]} -eq 0 ]; then
        echo "Waiting for TTFT measurements..."
        return
    fi
    
    # Calculate statistics
    local sum=0
    local min=${ttft_values[0]}
    local max=${ttft_values[0]}
    
    for val in "${ttft_values[@]}"; do
        sum=$((sum + val))
        [[ $val -lt $min ]] && min=$val
        [[ $val -gt $max ]] && max=$val
    done
    
    local avg=$((sum / ${#ttft_values[@]}))
    local p50=$(percentile 50)
    local p90=$(percentile 90)
    local p95=$(percentile 95)
    local p99=$(percentile 99)
    
    # Display current stats
    echo -e "${CYAN}Measurements:${NC} ${#ttft_values[@]}"
    echo ""
    echo -e "${BLUE}Current Statistics:${NC}"
    printf "  Min:     %4d ms\n" "$min"
    printf "  Max:     %4d ms\n" "$max"
    printf "  Average: %4d ms\n" "$avg"
    echo ""
    echo -e "${YELLOW}Percentiles:${NC}"
    printf "  P50:     %4d ms" "$p50"
    if [ $p50 -lt 150 ]; then
        echo -e " ${GREEN}✓${NC}"
    else
        echo -e " ${RED}✗${NC}"
    fi
    
    printf "  P90:     %4d ms" "$p90"
    if [ $p90 -lt 250 ]; then
        echo -e " ${GREEN}✓${NC}"
    else
        echo -e " ${RED}✗${NC}"
    fi
    
    printf "  P95:     %4d ms\n" "$p95"
    printf "  P99:     %4d ms\n" "$p99"
    
    # Show last 5 measurements
    echo -e "\n${BLUE}Recent Measurements:${NC}"
    local start=$((${#ttft_values[@]} - 5))
    [[ $start -lt 0 ]] && start=0
    
    for ((i = start; i < ${#ttft_values[@]}; i++)); do
        local timestamp="${timestamps[$i]}"
        local value="${ttft_values[$i]}"
        printf "  %s: %4d ms" "$timestamp" "$value"
        
        # Color code based on value
        if [ $value -lt 150 ]; then
            echo -e " ${GREEN}●${NC}"
        elif [ $value -lt 250 ]; then
            echo -e " ${YELLOW}●${NC}"
        else
            echo -e " ${RED}●${NC}"
        fi
    done
    
    # Performance bar chart
    echo -e "\n${BLUE}Performance Distribution:${NC}"
    local under_150=0
    local under_250=0
    local over_250=0
    
    for val in "${ttft_values[@]}"; do
        if [ $val -lt 150 ]; then
            ((under_150++))
        elif [ $val -lt 250 ]; then
            ((under_250++))
        else
            ((over_250++))
        fi
    done
    
    local total=${#ttft_values[@]}
    local pct_150=$((under_150 * 100 / total))
    local pct_250=$((under_250 * 100 / total))
    local pct_over=$((over_250 * 100 / total))
    
    printf "  <150ms: %3d%% " "$pct_150"
    printf "${GREEN}"
    for ((i=0; i<pct_150/2; i++)); do printf "█"; done
    printf "${NC}\n"
    
    printf "  <250ms: %3d%% " "$pct_250"
    printf "${YELLOW}"
    for ((i=0; i<pct_250/2; i++)); do printf "█"; done
    printf "${NC}\n"
    
    printf "  >250ms: %3d%% " "$pct_over"
    printf "${RED}"
    for ((i=0; i<pct_over/2; i++)); do printf "█"; done
    printf "${NC}\n"
    
    echo -e "\n${CYAN}Press Ctrl+C to stop monitoring${NC}"
}

# Function to save results
save_results() {
    if [ ${#ttft_values[@]} -eq 0 ]; then
        return
    fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$PROJECT_ROOT/ttft_monitor_results_$timestamp.json"
    
    # Calculate final stats
    local sum=0
    for val in "${ttft_values[@]}"; do
        sum=$((sum + val))
    done
    local avg=$((sum / ${#ttft_values[@]}))
    
    cat > "$output_file" << EOF
{
  "monitor_session": {
    "start_time": "${timestamps[0]}",
    "end_time": "${timestamps[-1]}",
    "duration_minutes": $((SECONDS / 60)),
    "total_measurements": ${#ttft_values[@]}
  },
  "statistics": {
    "min_ms": $(percentile 0),
    "max_ms": $(percentile 100),
    "avg_ms": $avg,
    "p50_ms": $(percentile 50),
    "p90_ms": $(percentile 90),
    "p95_ms": $(percentile 95),
    "p99_ms": $(percentile 99)
  },
  "performance": {
    "p50_target_met": $([ $(percentile 50) -lt 150 ] && echo "true" || echo "false"),
    "p90_target_met": $([ $(percentile 90) -lt 250 ] && echo "true" || echo "false")
  },
  "raw_measurements": [
$(printf '    %s\n' "${ttft_values[@]}" | sed '$ ! s/$/,/')
  ]
}
EOF
    
    echo -e "\n${GREEN}Results saved to: $output_file${NC}"
}

# Cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}Stopping monitor...${NC}"
    save_results
    exit 0
}

trap cleanup EXIT INT TERM

# Main monitoring loop
main() {
    echo -e "${GREEN}Starting TTFT real-time monitor...${NC}"
    
    # Check if server log exists
    if [[ ! -f "$SERVER_LOG" ]]; then
        echo -e "${RED}Server log not found: $SERVER_LOG${NC}"
        echo "Make sure the server is running and logging to this file."
        echo "You can specify a different log file with: SERVER_LOG=/path/to/log $0"
        exit 1
    fi
    
    # Start monitoring
    echo "Monitoring server log for TTFT measurements..."
    
    # Follow the log file
    tail -f "$SERVER_LOG" 2>/dev/null | while IFS= read -r line; do
        # Look for TTFT measurements in the log
        if echo "$line" | grep -q "TTFT:"; then
            # Extract TTFT value
            local ttft=$(echo "$line" | grep -oE "TTFT: [0-9]+ms" | awk '{print $2}' | sed 's/ms//')
            if [[ -n "$ttft" ]]; then
                # Add to arrays
                ttft_values+=("$ttft")
                timestamps+=("$(date +%H:%M:%S)")
                
                # Display stats every N measurements
                if [ $((${#ttft_values[@]} % STATS_INTERVAL)) -eq 0 ] || [ ${#ttft_values[@]} -eq 1 ]; then
                    display_stats
                fi
            fi
        fi
        
        # Also look for connection events
        if echo "$line" | grep -q "DataChannel opened"; then
            echo -e "\n${GREEN}[$(date +%H:%M:%S)] WebRTC connection established${NC}"
            sleep 2
            display_stats
        elif echo "$line" | grep -q "E2E encryption established"; then
            echo -e "\n${GREEN}[$(date +%H:%M:%S)] E2E encryption active${NC}"
            sleep 2
            display_stats
        elif echo "$line" | grep -q "connection closed"; then
            echo -e "\n${YELLOW}[$(date +%H:%M:%S)] Connection closed${NC}"
            sleep 2
            display_stats
        fi
    done &
    
    # Keep the script running
    wait
}

# Run main
main