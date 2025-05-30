#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Variables
LOG_FILE="/var/log/auth.log"  # On CentOS/Red Hat use: /var/log/secure
OUTPUT="brute_force_report_$(date +%Y%m%d_%H%M%S).txt"
THRESHOLD=5     # Number of failed attempts before flagging
TIME_WINDOW=300 # Time window in seconds (5 minutes)

# Check if log file exists
if [[ ! -f "$LOG_FILE" ]]; then
    echo -e "${RED}Log file $LOG_FILE not found. Exiting.${NC}"
    exit 1
fi

echo "====== Brute Force Detection Report ======" > "$OUTPUT"
echo "Analyzing: $LOG_FILE" >> "$OUTPUT"
echo "Generated on: $(date)" >> "$OUTPUT"
echo "----------------------------------------" >> "$OUTPUT"

# Extract failed login attempts with timestamps and IPs
echo "[+] Scanning for brute force attempts..." | tee -a "$OUTPUT"
awk '/Failed password/ {print $1, $2, $3, $(NF-3)}' "$LOG_FILE" | \
while read -r month day time ip; do
    # Convert timestamp to epoch
    log_time_epoch=$(date -d "$month $day $time" +%s)
    echo "$log_time_epoch $ip"
done | sort -n | \
awk -v threshold=$THRESHOLD -v window=$TIME_WINDOW '
{
    ip=$2
    time=$1
    count[ip]++
    times[ip,count[ip]]=time
}
END {
    for (ip in count) {
        for (i=1; i<=count[ip]-threshold+1; i++) {
            if (times[ip,i+threshold-1] - times[ip,i] <= window) {
                printf "[!] Possible brute force attack from %s: %d attempts within %d seconds\n", ip, threshold, window
                break
            }
        }
    }
}' | tee -a "$OUTPUT"

echo -e "\n${GREEN}[+] Detection complete. Report saved to $OUTPUT${NC}"
