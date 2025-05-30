#!/bin/bash

# Port Scanner Script - Reusable & Git-Safe
# Usage: ./port_scanner.sh <target_ip_or_hostname> [start_port] [end_port]

# === Appearance Colors ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# === Defaults ===
START_PORT=1
END_PORT=1000
TIMEOUT=2

# === Log Directory (Outside Git Folder) ===
LOG_DIR="$HOME/Documents/scan_logs"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/scan_results_${TIMESTAMP}.log"

# === Usage Info ===
usage() {
    echo "Usage: $0 <target_ip_or_hostname> [start_port] [end_port]"
    echo "Example: $0 192.168.1.100 1 65535"
    exit 1
}

# === Port Check Function ===
check_port() {
    local TARGET=$1
    local PORT=$2

    if timeout $TIMEOUT bash -c "echo >/dev/tcp/$TARGET/$PORT" 2>/dev/null; then
        local BANNER=$(timeout 1 bash -c "echo '' | nc -n $TARGET $PORT 2>/dev/null" | head -1 | tr -d '\r\n')
        
        # Basic Service Detection
        local SERVICE="unknown"
        case $PORT in
            21) SERVICE="FTP" ;;
            22) SERVICE="SSH" ;;
            23) SERVICE="Telnet" ;;
            25) SERVICE="SMTP" ;;
            53) SERVICE="DNS" ;;
            80) SERVICE="HTTP" ;;
            110) SERVICE="POP3" ;;
            143) SERVICE="IMAP" ;;
            443) SERVICE="HTTPS" ;;
            3306) SERVICE="MySQL" ;;
            3389) SERVICE="RDP" ;;
            5432) SERVICE="PostgreSQL" ;;
        esac

        printf "${GREEN}[+]${NC} Port ${BLUE}%-5s${NC} OPEN (%s)" "$PORT" "$SERVICE"
        [[ -n "$BANNER" ]] && printf " - %s" "$BANNER"
        printf "\n"

        echo "$(date): $TARGET:$PORT OPEN ($SERVICE) - $BANNER" >> "$LOG_FILE"
    fi
}

# === Input Validation ===
if [[ $# -lt 1 ]]; then
    usage
fi

TARGET=$1
START_PORT=${2:-$START_PORT}
END_PORT=${3:-$END_PORT}

# === Check Target Reachability ===
if ! ping -c 1 -W 2 "$TARGET" >/dev/null 2>&1; then
    echo -e "${RED}[-]${NC} Host $TARGET is not reachable."
fi

echo -e "${YELLOW}[*]${NC} Starting scan on ${BLUE}$TARGET${NC}"
echo "Port Range: $START_PORT-$END_PORT"
echo "Timeout per port: ${TIMEOUT}s"
echo

START_TIME=$(date +%s)

# === Start Port Scan ===
for ((PORT=START_PORT; PORT<=END_PORT; PORT++)); do
    check_port "$TARGET" "$PORT" &
    (( $(jobs -r | wc -l) >= 50 )) && wait
done

wait

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo
echo -e "${GREEN}[✓]${NC} Scan completed in ${DURATION} seconds"
echo -e "${BLUE}[>]${NC} Results saved to: $LOG_FILE"
