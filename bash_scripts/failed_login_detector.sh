#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}====== Failed Login Detector ======${NC}"
echo "Timestamp: $(date)"
echo "-----------------------------------"

# Detect which log file to use
if [[ -f /var/log/auth.log ]]; then
    LOG_FILE="/var/log/auth.log"
elif [[ -f /var/log/secure ]]; then
    LOG_FILE="/var/log/secure"
else
    echo -e "${RED}No supported log file found (auth.log or secure).${NC}"
    exit 1
fi

echo -e "${BLUE}[+] Parsing log file: $LOG_FILE${NC}"

# Show last 10 failed login attempts
echo -e "${YELLOW}Recent failed login attempts:${NC}"
grep -i "failed password" "$LOG_FILE" | tail -n 10

# Show top offending IPs
echo -e "${YELLOW}Top IP addresses with failed login attempts:${NC}"
grep -i "failed password" "$LOG_FILE" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) print $i}' | sort | uniq -c | sort -nr | head

# Show invalid usernames
echo -e "${YELLOW}Invalid user attempts:${NC}"
grep -i "invalid user" "$LOG_FILE" | awk '{print $(NF)}' | sort | uniq -c | sort -nr | head

echo "-----------------------------------"
echo -e "${GREEN}====== Scan Complete ======${NC}"
