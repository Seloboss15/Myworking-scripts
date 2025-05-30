#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}====== Suspicious Activity Monitor ======${NC}"
echo "Timestamp: $(date)"
echo "----------------------------------------"

# 1. Recent sudo use
echo -e "${YELLOW}[+] Recent sudo activity:${NC}"
sudo grep 'COMMAND=' /var/log/auth.log | tail -n 10
echo ""

# 2. New users added recently
echo -e "${YELLOW}[+] Recently created user accounts (last 7 days):${NC}"
sudo find /home -type d -ctime -7 -exec ls -ld {} \;
echo ""

# 3. Login attempts from unknown IPs
echo -e "${YELLOW}[+] Unusual login IPs (last 20 attempts):${NC}"
last -a | head -n 20
echo ""

# 4. High CPU usage processes
echo -e "${YELLOW}[+] Top 5 CPU consuming processes:${NC}"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6
echo ""

# 5. High memory usage processes
echo -e "${YELLOW}[+] Top 5 memory consuming processes:${NC}"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6
echo ""

# 6. Unusual listening ports
echo -e "${YELLOW}[+] Listening network ports (non-standard):${NC}"
sudo ss -tuln | grep -vE '(:22|:80|:443)' | grep LISTEN
echo ""

# 7. Suspicious cron jobs
echo -e "${YELLOW}[+] Suspicious cron jobs (including hidden scripts):${NC}"
sudo crontab -l 2>/dev/null
sudo ls -la /etc/cron* /var/spool/cron 2>/dev/null | grep '\.'
echo ""

# 8. Hidden files in home directories
echo -e "${YELLOW}[+] Hidden files in user home directories:${NC}"
sudo find /home -type f -name ".*" -ls | head -n 10
echo ""

echo -e "${GREEN}====== Scan Complete ======${NC}"
