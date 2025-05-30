#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Usage check
if [ -z "$1" ]; then
    echo -e "${RED}[!] Usage: $0 <domain>${NC}"
    exit 1
fi

DOMAIN=$1
PORT=443
DATE=$(date +%Y%m%d_%H%M%S)
OUTPUT="ssl_cert_check_${DOMAIN}_${DATE}.txt"

echo -e "${YELLOW}=== SSL Certificate Check for $DOMAIN ===${NC}" | tee "$OUTPUT"
echo "Timestamp: $(date)" | tee -a "$OUTPUT"
echo "----------------------------------------" | tee -a "$OUTPUT"

# Fetch SSL Certificate
echo -e "${GREEN}[+] Retrieving SSL certificate info...${NC}" | tee -a "$OUTPUT"
CERT_INFO=$(echo | timeout 10 openssl s_client -connect "$DOMAIN:$PORT" -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -text)

if [ -z "$CERT_INFO" ]; then
    echo -e "${RED}[!] Failed to retrieve SSL certificate. Host may be down or not support SSL.${NC}" | tee -a "$OUTPUT"
    exit 1
fi

# Extract Certificate Details
echo -e "\n${YELLOW}[+] Certificate Details:${NC}" | tee -a "$OUTPUT"
CN=$(echo "$CERT_INFO" | grep "Subject:" | grep -o "CN=.*" | head -n1)
ISSUER=$(echo "$CERT_INFO" | grep "Issuer:" | head -n1 | sed 's/^ *//')
VALID_FROM=$(echo "$CERT_INFO" | grep "Not Before" | sed 's/^ *//')
VALID_TO=$(echo "$CERT_INFO" | grep "Not After" | sed 's/^ *//')
SAN=$(echo "$CERT_INFO" | grep -A1 "Subject Alternative Name" | tail -n1 | sed 's/^ *//')

echo "Common Name         : $CN" | tee -a "$OUTPUT"
echo "Issuer              : $ISSUER" | tee -a "$OUTPUT"
echo "Valid From          : $VALID_FROM" | tee -a "$OUTPUT"
echo "Valid To            : $VALID_TO" | tee -a "$OUTPUT"
echo "Subject Alt Names   : $SAN" | tee -a "$OUTPUT"

# Expiry Warning
EXP_DATE=$(echo "$VALID_TO" | awk -F'Not After :' '{print $2}')
EXP_SECONDS=$(date -d "$EXP_DATE" +%s)
NOW_SECONDS=$(date +%s)
DAYS_LEFT=$(( ($EXP_SECONDS - $NOW_SECONDS) / 86400 ))

echo -e "\n${YELLOW}[+] Certificate Expiration Check:${NC}" | tee -a "$OUTPUT"
if [ $DAYS_LEFT -lt 0 ]; then
    echo -e "${RED}❌ Certificate expired $((-DAYS_LEFT)) days ago!${NC}" | tee -a "$OUTPUT"
elif [ $DAYS_LEFT -lt 30 ]; then
    echo -e "${YELLOW}⚠️  Certificate will expire in $DAYS_LEFT days.${NC}" | tee -a "$OUTPUT"
else
    echo -e "${GREEN}✅ Certificate is valid for another $DAYS_LEFT days.${NC}" | tee -a "$OUTPUT"
fi

# SSL/TLS Cipher & Vulnerability Scan
echo -e "\n${GREEN}[+] Running SSL scan with Nmap...${NC}" | tee -a "$OUTPUT"
nmap --script ssl-enum-ciphers -p $PORT "$DOMAIN" | tee -a "$OUTPUT"

# Optionally: Add Heartbleed scan
# echo -e "\n${YELLOW}[+] Checking for Heartbleed vulnerability...${NC}" | tee -a "$OUTPUT"
# nmap --script ssl-heartbleed -p $PORT "$DOMAIN" | tee -a "$OUTPUT"

echo -e "\n${GREEN}✅ SSL certificate check complete. Output saved to: $OUTPUT${NC}"
