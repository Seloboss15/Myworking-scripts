#!/bin/bash

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if domain is provided
if [ -z "$1" ]; then
    echo -e "${RED}[!] Usage: $0 <domain>${NC}"
    exit 1
fi

DOMAIN=$1
DATE=$(date +%Y%m%d_%H%M%S)
OUTPUT="dns_enum_${DOMAIN}_${DATE}.txt"

echo -e "${BLUE}====== DNS Enumeration for $DOMAIN ======${NC}" | tee "$OUTPUT"
echo "Timestamp: $(date)" | tee -a "$OUTPUT"
echo "----------------------------------------" | tee -a "$OUTPUT"

# Function to run dig and print records
print_record() {
    local type=$1
    echo -e "\n${GREEN}[+] ${type} Records:${NC}" | tee -a "$OUTPUT"
    dig +short "$DOMAIN" "$type" | tee -a "$OUTPUT"
}

# Record Types
print_record A
print_record AAAA
print_record MX
print_record NS
print_record TXT
print_record SOA

# CNAME Record for www
echo -e "\n${GREEN}[+] CNAME (www):${NC}" | tee -a "$OUTPUT"
dig +short www."$DOMAIN" CNAME | tee -a "$OUTPUT"

# Attempt Zone Transfer
echo -e "\n${YELLOW}[+] Attempting Zone Transfer (AXFR):${NC}" | tee -a "$OUTPUT"
NS_SERVERS=$(dig +short "$DOMAIN" NS)

for ns in $NS_SERVERS; do
    echo -e "\n[AXFR attempt] Trying $ns...." | tee -a "$OUTPUT"
    dig @$ns "$DOMAIN" AXFR | tee -a "$OUTPUT"
done

# Reverse DNS Lookup (PTR)
echo -e "\n${GREEN}[+] Reverse DNS Lookup (PTR):${NC}" | tee -a "$OUTPUT"
A_RECORD=$(dig +short "$DOMAIN" A | head -n 1)
if [ -n "$A_RECORD" ]; then
    PTR=$(dig -x "$A_RECORD" +short)
    echo "$A_RECORD -> $PTR" | tee -a "$OUTPUT"
else
    echo "No A record found for PTR lookup" | tee -a "$OUTPUT"
fi

# WHOIS Info
echo -e "\n${GREEN}[+] WHOIS Info:${NC}" | tee -a "$OUTPUT"
WHOIS=$(whois "$DOMAIN")
echo "$WHOIS" | tee -a "$OUTPUT"

# Extract Key WHOIS Fields
echo -e "\n${BLUE}[+] WHOIS Summary:${NC}" | tee -a "$OUTPUT"
REGISTRAR=$(echo "$WHOIS" | grep -i "Registrar:" | head -n 1 | cut -d ':' -f2-)
CREATION=$(echo "$WHOIS" | grep -i "Creation Date:" | head -n 1 | cut -d ':' -f2-)
EXPIRY=$(echo "$WHOIS" | grep -i "Expiry Date\|Expiration Date" | head -n 1 | cut -d ':' -f2-)
echo "Registrar     : $REGISTRAR" | tee -a "$OUTPUT"
echo "Creation Date : $CREATION" | tee -a "$OUTPUT"
echo "Expiry Date   : $EXPIRY" | tee -a "$OUTPUT"

# SPF / DMARC / DKIM
echo -e "\n${YELLOW}[+] SPF / DMARC / DKIM Records:${NC}" | tee -a "$OUTPUT"
TXT_RECORDS=$(dig +short "$DOMAIN" TXT)

echo -e "\nSPF Records:" | tee -a "$OUTPUT"
echo "$TXT_RECORDS" | grep -i "v=spf1" | tee -a "$OUTPUT"

echo -e "\nDMARC Record (_dmarc.$DOMAIN):" | tee -a "$OUTPUT"
dig +short _dmarc."$DOMAIN" TXT | tee -a "$OUTPUT"

echo -e "\nDKIM Records (selector1._domainkey.$DOMAIN):" | tee -a "$OUTPUT"
dig +short selector1._domainkey."$DOMAIN" TXT | tee -a "$OUTPUT"

# Final Summary
echo -e "\n${BLUE}[+] Final Summary:${NC}" | tee -a "$OUTPUT"
RECORDS_FOUND=$(grep -E "^\[+\]" "$OUTPUT" | wc -l)
echo "Total record types collected: $RECORDS_FOUND" | tee -a "$OUTPUT"
echo -e "${GREEN}✅ DNS enumeration complete. Output saved to: $OUTPUT${NC}"
