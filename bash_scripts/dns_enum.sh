#!/bin/bash

# Colors for formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check for domain input
if [ -z "$1" ]; then
    echo -e "${RED}[!] Usage: $0 <domain>${NC}"
    exit 1
fi

DOMAIN=$1
OUTPUT_FILE="dns_enum_${DOMAIN}_$(date +%Y%m%d_%H%M%S).txt"

echo -e "${CYAN}[*] Starting DNS Enumeration for: ${DOMAIN}${NC}"
echo -e "[*] Output will be saved to ${OUTPUT_FILE}\n"

{
    echo "====== DNS Enumeration for $DOMAIN ======"
    echo "Timestamp: $(date)"
    echo "----------------------------------------"
    
    echo -e "\n[+] A Records:"
    dig +short A $DOMAIN

    echo -e "\n[+] AAAA Records:"
    dig +short AAAA $DOMAIN

    echo -e "\n[+] MX Records:"
    dig +short MX $DOMAIN

    echo -e "\n[+] NS Records:"
    dig +short NS $DOMAIN

    echo -e "\n[+] TXT Records:"
    dig +short TXT $DOMAIN

    echo -e "\n[+] SOA Record:"
    dig +short SOA $DOMAIN

    echo -e "\n[+] CNAME (if any):"
    dig +short CNAME $DOMAIN

    echo -e "\n[+] Attempting Zone Transfer (AXFR):"
    for ns in $(dig +short NS $DOMAIN); do
        echo -e "\n[AXFR attempt] Trying $ns..."
        dig @$ns $DOMAIN AXFR
    done

    echo -e "\n[+] Reverse DNS Lookup (PTR):"
    ip=$(dig +short $DOMAIN | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1)
    if [ -n "$ip" ]; then
        ptr=$(dig -x $ip +short)
        echo "$ip -> $ptr"
    else
        echo "No A record IP found for PTR lookup."
    fi

    echo -e "\n[+] WHOIS Info:"
    whois $DOMAIN 2>/dev/null | head -n 20

    echo -e "\n====== End of Report ======"
} | tee "$OUTPUT_FILE"

echo -e "\n${GREEN}[+] DNS Enumeration completed. Results saved in: ${OUTPUT_FILE}${NC}"
