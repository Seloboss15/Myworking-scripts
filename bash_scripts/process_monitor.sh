#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOG_FILE="process_monitor_$(date +%Y%m%d_%H%M%S).log"

echo -e "${YELLOW}========== Real-Time Process Monitor ==========${NC}"
echo "Logging to: $LOG_FILE"
echo "Press Ctrl+C to stop monitoring"
echo "=============================================="

# Header for log file
echo "==== Process Monitor Log Started at $(date) ====" > "$LOG_FILE"

# Main Monitoring Loop
while true; do
    echo -e "\n$(date) - Top 10 Processes by CPU Usage" | tee -a "$LOG_FILE"
    ps -eo pid,ppid,user,%cpu,%mem,cmd --sort=-%cpu | head -n 11 | tee -a "$LOG_FILE"

    echo -e "\n$(date) - Top 10 Processes by Memory Usage" | tee -a "$LOG_FILE"
    ps -eo pid,ppid,user,%cpu,%mem,cmd --sort=-%mem | head -n 11 | tee -a "$LOG_FILE"

    echo -e "\n$(date) - Processes with Network Connections" | tee -a "$LOG_FILE"
    lsof -i -n -P | grep -i estab | awk '{print $1, $2, $3, $9}' | sort | uniq | tee -a "$LOG_FILE"

    echo -e "\n$(date) - Suspicious Commands (grep for known suspicious names)" | tee -a "$LOG_FILE"
    ps aux | grep -E 'nc|ncat|netcat|bash|sh|python|perl|reverse|crypto|miner' | grep -v grep | tee -a "$LOG_FILE"

    echo -e "${GREEN}--- Waiting 5 seconds before next scan ---${NC}"
    sleep 5
done

