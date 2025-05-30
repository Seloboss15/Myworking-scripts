#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}====== Multi-Format Log Analyzer ======${NC}"
echo "Timestamp: $(date)"
echo "---------------------------------------"
echo

LOG_FILES=(
    "/var/log/syslog"
    "/var/log/messages"
    "/var/log/auth.log"
    "/var/log/nginx/access.log"
    "/var/log/nginx/error.log"
    "/var/log/apache2/access.log"
    "/var/log/apache2/error.log"
)

for LOG in "${LOG_FILES[@]}"; do
    if [[ -f "$LOG" ]]; then
        echo -e "${BLUE}[+] Analyzing: $LOG${NC}"

        echo -e "${YELLOW}  -> Top 10 frequent entries:${NC}"
        awk '{print $6}' "$LOG" | sort | uniq -c | sort -nr | head -10

        echo -e "${YELLOW}  -> Failed logins / Authentication issues:${NC}"
        grep -i 'fail\|denied\|authentication failure\|invalid user' "$LOG" | tail -n 5

        echo -e "${YELLOW}  -> Sudo usage (if any):${NC}"
        grep -i 'sudo' "$LOG" | tail -n 5

        echo -e "${YELLOW}  -> HTTP 4xx/5xx errors (if web log):${NC}"
        grep -E ' 4[0-9]{2} | 5[0-9]{2} ' "$LOG" | tail -n 5

        echo "---------------------------------------"
    fi
done

echo -e "${GREEN}====== Log Analysis Complete ======${NC}"
