#!/bin/bash

# Cross-Platform TCP Port Scanner for Security Analysts
# Works on Linux, Ubuntu, and macOS (requires gtimeout via Homebrew)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
START_PORT=1
END_PORT=1000
TIMEOUT=2
MAX_CONCURRENT=50
LOG_FILE="scan_results_$(date +%Y%m%d_%H%M%S).log"

# Detect proper timeout command
if command -v timeout >/dev/null 2>&1; then
    TIMEOUT_CMD="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
    TIMEOUT_CMD="gtimeout"
else
    echo -e "${RED}[!] No 'timeout' command found.${NC} Install with: ${YELLOW}sudo apt install coreutils${NC} (Linux) or ${YELLOW}brew install coreutils${NC} (macOS)"
    exit 1
fi

# Usage help
usage() {
    echo -e "Usage: $0 <target> [start_port] [end_port]"
    echo -e "Example: $0 192.168.1.10 20 1024"
    exit 1
}

# Input check
if [[ -z "$1" ]]; then
    usage
fi

TARGET=$1
START_PORT=${2:-$START_PORT}
END_PORT=${3:-$END_PORT}

# Optional: ping check
if ! ping -c 1 -W 1 "$TARGET" &>/dev/null; then
    echo -e "${RED}[-] Host $TARGET is not reachable.${NC}"
fi

# Banner
echo -e "${YELLOW}[*] Starting scan on $TARGET${NC}"
echo -e "${BLUE}Port Range:${NC} $START_PORT-$END_PORT"
echo -e "${BLUE}Timeout per port:${NC} ${TIMEOUT}s"
echo

# Scan function
scan_port() {
    local port=$1
    if nc -z -w $TIMEOUT $TARGET $port 2>/dev/null; then
        local banner=$($TIMEOUT_CMD 2 bash -c "echo '' | nc $TARGET $port 2>/dev/null" | head -1 | tr -d '\r\n')
        echo -e "${GREEN}[+] Port $port OPEN${NC} ${YELLOW}${banner}${NC}"
        echo "$(date '+%F %T') $TARGET:$port OPEN - $banner" >> "$LOG_FILE"
    fi
}

# Timer
start_time=$(date +%s)

# Start scanning
for ((port=$START_PORT; port<=$END_PORT; port++)); do
    scan_port $port &

    # Limit concurrent jobs
    while [ "$(jobs -r | wc -l)" -ge "$MAX_CONCURRENT" ]; do
        sleep 0.1
    done
done

wait
end_time=$(date +%s)

# Done
echo
echo -e "${YELLOW}[✓] Scan completed in $((end_time - start_time)) seconds${NC}"
echo -e "${BLUE}[>] Results saved to:${NC} $LOG_FILE"

