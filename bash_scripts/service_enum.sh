#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}====== Running Services Enumeration and Analysis ======${NC}"
echo "Timestamp: $(date)"
echo "-------------------------------------------------------"
echo

# Check if systemctl is available
if command -v systemctl &> /dev/null; then
    echo -e "${YELLOW}[+] Listing all active running services:${NC}"
    systemctl list-units --type=service --state=running | awk 'NR>1 {print $1, $3, $4}' | column -t
    echo

    echo -e "${YELLOW}[+] Listing all enabled services:${NC}"
    systemctl list-unit-files --type=service --state=enabled | awk 'NR>1 {print $1, $2}' | column -t
    echo
else
    echo -e "${RED}systemctl command not found. Trying service command...${NC}"
    service --status-all 2>/dev/null | grep '\[ + \]'
    echo
fi

# Show listening ports and associated services
echo -e "${YELLOW}[+] Currently listening ports and associated processes:${NC}"
if command -v ss &> /dev/null; then
    ss -tulnp | awk 'NR==1 || NR==2 || NR==3 {print} NR>3 {print $0}' | column -t
elif command -v netstat &> /dev/null; then
    sudo netstat -tulnp | column -t
else
    echo -e "${RED}Neither ss nor netstat is installed.${NC}"
fi

echo
echo -e "${GREEN}====== End of Service Enumeration ======${NC}"
