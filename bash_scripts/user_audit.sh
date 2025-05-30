#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}====== User Account and Privilege Audit ======${NC}"
echo "Timestamp: $(date)"
echo "-----------------------------------------------"
echo

echo -e "${YELLOW}[+] All user accounts:${NC}"
printf "%-20s %-8s %-25s %-20s\n" "Username" "UID" "Home Directory" "Shell"
awk -F: '{ printf "%-20s %-8s %-25s %-20s\n", $1, $3, $6, $7 }' /etc/passwd
echo

echo -e "${YELLOW}[+] Users with UID 0 (Root or equivalent):${NC}"
awk -F: '$3 == 0 { print $1 }' /etc/passwd
echo

echo -e "${YELLOW}[+] Users in sudo or admin groups:${NC}"
getent group sudo admin wheel | awk -F: '{print $4}' | tr ',' '\n' | sort | uniq
echo

echo -e "${YELLOW}[+] Users with no password (shadow file check):${NC}"
awk -F: '($2 == "" || $2 == "*" || $2 == "!" ) {print $1}' /etc/shadow 2>/dev/null || echo "No access to /etc/shadow or no such users."
echo

echo -e "${YELLOW}[+] Last login info for users:${NC}"
lastlog | head -n 15
echo

echo -e "${YELLOW}[+] Disabled or locked accounts:${NC}"
passwd -S -a | grep -E 'locked|L' || echo "No locked accounts found."
echo

echo -e "${GREEN}====== End of Audit ======${NC}"
