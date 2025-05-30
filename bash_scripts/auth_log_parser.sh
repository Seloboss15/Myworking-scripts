#!/bin/bash

# Color setup
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Log file (update this if using a non-Ubuntu system)
AUTH_LOG="/var/log/auth.log"

# Timestamped output file
HOST=$(hostname)
TIME=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="auth_log_report_${HOST}_${TIME}.txt"

echo -e "${GREEN}====== Authentication Log Analysis ======${NC}" | tee "$OUTPUT_FILE"
echo "Host: $HOST" | tee -a "$OUTPUT_FILE"
echo "Date: $(date)" | tee -a "$OUTPUT_FILE"
echo "----------------------------------------" | tee -a "$OUTPUT_FILE"

# 1. Failed login attempts
echo -e "${YELLOW}[+] Failed login attempts:${NC}" | tee -a "$OUTPUT_FILE"
grep "Failed password" "$AUTH_LOG" | awk '{print $(NF-3), $(NF-5), $1, $2, $3}' | sort | uniq -c | sort -nr | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 2. Successful logins
echo -e "${YELLOW}[+] Successful logins:${NC}" | tee -a "$OUTPUT_FILE"
grep "Accepted password" "$AUTH_LOG" | awk '{print $(NF-3), $(NF-5), $1, $2, $3}' | sort | uniq -c | sort -nr | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 3. Invalid user attempts
echo -e "${YELLOW}[+] Invalid user login attempts:${NC}" | tee -a "$OUTPUT_FILE"
grep "Invalid user" "$AUTH_LOG" | awk '{print $(NF), $(NF-1), $1, $2, $3}' | sort | uniq -c | sort -nr | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 4. Root login attempts
echo -e "${YELLOW}[+] Root login attempts:${NC}" | tee -a "$OUTPUT_FILE"
grep "user root" "$AUTH_LOG" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 5. Sudo usage logs
echo -e "${YELLOW}[+] Sudo command usage:${NC}" | tee -a "$OUTPUT_FILE"
grep "sudo:" "$AUTH_LOG" | awk -F ':' '{print $4}' | sort | uniq -c | sort -nr | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 6. SSH connection attempts
echo -e "${YELLOW}[+] SSH connection attempts:${NC}" | tee -a "$OUTPUT_FILE"
grep "sshd" "$AUTH_LOG" | grep "Connection from" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 7. Suspicious activity
echo -e "${YELLOW}[+] Suspicious authentication log entries (scan keywords):${NC}" | tee -a "$OUTPUT_FILE"
grep -Ei "illegal|failure|error|denied|unauthorized" "$AUTH_LOG" | tail -n 20 | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

echo -e "${GREEN}====== Analysis Complete ======${NC}" | tee -a "$OUTPUT_FILE"
