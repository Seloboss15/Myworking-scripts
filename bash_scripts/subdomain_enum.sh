#!/bin/bash

# Subdomain Enumeration Script
# Description: Enumerate subdomains using multiple methods
# Usage: ./subdomain_enum.sh example.com

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check input
if [ -z "$1" ]; then
    echo -e "${RED}[!] Usage: $0 <domain>${NC}"
    exit 1
fi

DOMAIN=$1
OUTPUT_FILE="subdomain_enum_${DOMAIN}_$(date +%Y%m%d_%H%M%S).txt"

echo -e "${YELLOW}[*] Starting subdomain enumeration for: ${DOMAIN}${NC}"

# Function to print results nicely
print_section() {
    echo -e "\n${BLUE}==> $1${NC}" | tee -a "$OUTPUT_FILE"
}

# crt.sh method
enum_crtsh() {
    print_section "crt.sh enumeration"
    curl -s "https://crt.sh/?q=%25.${DOMAIN}&output=json" | \
    jq -r '.[].name_value' 2>/dev/null | \
    sed 's/\*\.//g' | sort -u | tee -a "$OUTPUT_FILE"
}

# subfinder (if available)
enum_subfinder() {
    if command -v subfinder >/dev/null; then
        print_section "Subfinder enumeration"
        subfinder -d "$DOMAIN" -silent | tee -a "$OUTPUT_FILE"
    else
        echo -e "${RED}[!] subfinder not found${NC}"
    fi
}

# amass (if available)
enum_amass() {
    if command -v amass >/dev/null; then
        print_section "Amass enumeration"
        amass enum -passive -d "$DOMAIN" | tee -a "$OUTPUT_FILE"
    else
        echo -e "${RED}[!] amass not found${NC}"
    fi
}

# Brute-force using dig + wordlist
enum_bruteforce() {
    WORDLIST="/usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-5000.txt"
    
    if [[ ! -f "$WORDLIST" ]]; then
        echo -e "${RED}[!] Wordlist not found at $WORDLIST${NC}"
        return
    fi

    print_section "Brute-force with dig"
    for sub in $(cat "$WORDLIST"); do
        host "$sub.$DOMAIN" | grep -v "not found" | tee -a "$OUTPUT_FILE"
    done
}

# Resolve unique subdomains
resolve_subdomains() {
    print_section "DNS Resolution of discovered subdomains"
    sort -u "$OUTPUT_FILE" | while read -r sub; do
        dig +short "$sub" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | \
        awk -v s="$sub" '{print s " -> " $0}' | tee -a "$OUTPUT_FILE.resolved"
    done
}

# Start enumeration
enum_crtsh
enum_subfinder
enum_amass
enum_bruteforce

# Uncomment the line below to resolve found subdomains
# resolve_subdomains

echo -e "${GREEN}[+] Subdomain enumeration completed. Output saved to $OUTPUT_FILE${NC}"

