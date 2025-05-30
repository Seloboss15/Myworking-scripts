#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log file
HOST=$(hostname)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="process_monitor_${HOST}_${TIMESTAMP}.log"

echo -e "${GREEN}====== Real-Time Process Monitoring for $HOST ======${NC}" | tee -a "$LOG_FILE"
echo -e "Timestamp: $(date)\n" | tee -a "$LOG_FILE"

# Real-time top 10 CPU & Memory consuming processes
echo -e "${YELLOW}[+] Top 10 Processes by CPU Usage:${NC}" | tee -a "$LOG_FILE"
ps -eo pid,ppid,cmd,%cpu --sort=-%cpu | head -n 11 | tee -a "$LOG_FILE"

echo -e "\n${YELLOW}[+] Top 10 Processes by Memory Usage:${NC}" | tee -a "$LOG_FILE"
ps -eo pid,ppid,cmd,%mem --sort=-%mem | head -n 11 | tee -a "$LOG_FILE"

# Check for zombie processes
echo -e "\n${YELLOW}[+] Zombie Processes:${NC}" | tee -a "$LOG_FILE"
ps aux | awk '{ if ($8=="Z") print $0; }' | tee -a "$LOG_FILE"

# Rootkit Detection (chkrootkit)
if command -v chkrootkit >/dev/null; then
    echo -e "\n${YELLOW}[+] Running Rootkit Check (chkrootkit):${NC}" | tee -a "$LOG_FILE"
    sudo chkrootkit | tee -a "$LOG_FILE"
else
    echo -e "\n${RED}[-] chkrootkit not installed. Skipping rootkit scan.${NC}" | tee -a "$LOG_FILE"
fi

# User Activity Tracing
echo -e "\n${YELLOW}[+] Logged-In Users:${NC}" | tee -a "$LOG_FILE"
who | tee -a "$LOG_FILE"

echo -e "\n${YELLOW}[+] Last 5 Login Attempts:${NC}" | tee -a "$LOG_FILE"
last -n 5 | tee -a "$LOG_FILE"

# Auto-kill suspicious processes
echo -e "\n${YELLOW}[+] Scanning for suspicious processes (e.g., crypto, reverse shells)...${NC}" | tee -a "$LOG_FILE"
SUSPECTS=$(ps aux | grep -E 'crypto|minerd|reverse|nc|bash -i|perl -e|python -c' | grep -v grep)

if [ -n "$SUSPECTS" ]; then
    echo -e "${RED}[!] Suspicious processes detected. Terminating...${NC}" | tee -a "$LOG_FILE"
    echo "$SUSPECTS" | tee -a "$LOG_FILE"

    echo "$SUSPECTS" | awk '{print $2}' | while read pid; do
        kill -9 "$pid" && echo -e "${RED}Killed process PID: $pid${NC}" | tee -a "$LOG_FILE"
    done
else
    echo -e "${GREEN}[✓] No suspicious processes found.${NC}" | tee -a "$LOG_FILE"
fi

# Optional: Send Alert Email (requires mailx or similar configured)
# echo -e "Subject: Alert from $HOST\n\nSuspicious processes were found and terminated." | mailx -s "Process Alert" your@email.com

echo -e "\n${GREEN}Process monitoring completed. Log saved to ${LOG_FILE}${NC}"
