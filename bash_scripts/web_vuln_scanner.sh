#!/bin/bash

# Color Setup
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check usage
if [ -z "$1" ]; then
    echo -e "${RED}Usage: $0 <http(s)://target.com>${NC}"
    exit 1
fi

TARGET="$1"
DATE=$(date +%Y%m%d_%H%M%S)
OUTFILE="web_vuln_report_$(echo $TARGET | sed 's|https\?://||;s|/||g')_$DATE.txt"

echo -e "${GREEN}Starting Web Vulnerability Scan on $TARGET${NC}" | tee "$OUTFILE"
echo "Scan Time: $(date)" | tee -a "$OUTFILE"
echo "---------------------------------------------" | tee -a "$OUTFILE"

# 1. Check for open directories
echo -e "${YELLOW}[+] Checking for Open Directories...${NC}" | tee -a "$OUTFILE"
for dir in admin backup .git uploads test old; do
    url="$TARGET/$dir/"
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200"; then
        echo "[!] Found accessible directory: $url" | tee -a "$OUTFILE"
    fi
done
echo "" | tee -a "$OUTFILE"

# 2. Check for exposed config files
echo -e "${YELLOW}[+] Checking for Exposed Configuration Files...${NC}" | tee -a "$OUTFILE"
for file in .env config.php wp-config.php config.json; do
    url="$TARGET/$file"
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200"; then
        echo "[!] Found exposed config file: $url" | tee -a "$OUTFILE"
    fi
done
echo "" | tee -a "$OUTFILE"

# 3. Basic XSS test
echo -e "${YELLOW}[+] Checking for Reflected XSS...${NC}" | tee -a "$OUTFILE"
XSS_PAYLOAD="<script>alert(1)</script>"
XSS_TEST=$(curl -s "$TARGET/?xss=$XSS_PAYLOAD")
if echo "$XSS_TEST" | grep -q "$XSS_PAYLOAD"; then
    echo "[!] Possible XSS Reflection Detected at $TARGET/?xss=" | tee -a "$OUTFILE"
else
    echo "[+] No XSS reflection detected." | tee -a "$OUTFILE"
fi
echo "" | tee -a "$OUTFILE"

# 4. SQLi test
echo -e "${YELLOW}[+] Checking for Basic SQLi...${NC}" | tee -a "$OUTFILE"
SQLI_PAYLOAD="' OR '1'='1"
SQLI_TEST=$(curl -s "$TARGET/login.php?user=$SQLI_PAYLOAD&pass=$SQLI_PAYLOAD")
if echo "$SQLI_TEST" | grep -i -q "sql syntax\|mysql\|warning\|error"; then
    echo "[!] Possible SQL Injection point detected at login.php" | tee -a "$OUTFILE"
else
    echo "[+] No SQLi indicators detected." | tee -a "$OUTFILE"
fi
echo "" | tee -a "$OUTFILE"

# 5. HTTP headers security
echo -e "${YELLOW}[+] Analyzing HTTP Security Headers...${NC}" | tee -a "$OUTFILE"
HEADERS=$(curl -s -D - -o /dev/null "$TARGET")
echo "$HEADERS" | grep -E "Strict-Transport-Security|Content-Security-Policy|X-Content-Type-Options|X-Frame-Options|X-XSS-Protection" | tee -a "$OUTFILE"

MISSING_HEADERS=0
for h in "Content-Security-Policy" "Strict-Transport-Security" "X-Frame-Options"; do
    if ! echo "$HEADERS" | grep -q "$h"; then
        echo "[!] Missing recommended header: $h" | tee -a "$OUTFILE"
        ((MISSING_HEADERS++))
    fi
done
if [ "$MISSING_HEADERS" -eq 0 ]; then
    echo "[+] All major security headers found." | tee -a "$OUTFILE"
fi

echo "" | tee -a "$OUTFILE"

echo -e "${GREEN}Scan complete. Output saved to $OUTFILE${NC}"
