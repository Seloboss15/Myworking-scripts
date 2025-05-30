#!/bin/bash

# Network Discovery Script
# Description: Discover active hosts on a network segment
# Usage: ./network_discovery.sh <network_range>

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
TIMEOUT=2
PING_COUNT=1
OUTPUT_FILE="network_discovery_$(date +%Y%m%d_%H%M%S).txt"

usage() {
    echo "Usage: $0 <network_range>"
    echo "Examples:"
    echo "  $0 192.168.1.0/24"
    echo "  $0 10.0.0.1-10.0.0.254"
    echo "  $0 192.168.1.100"
    exit 1
}

# Function to ping a single host
ping_host() {
    local ip=$1
    if ping -c $PING_COUNT -W $TIMEOUT "$ip" >/dev/null 2>&1; then
        # Get hostname if possible
        local hostname=$(nslookup "$ip" 2>/dev/null | grep "name =" | cut -d'=' -f2 | sed 's/^ *//' | sed 's/\.$//') 
        
        # Get MAC address (works only on local network)
        local mac=$(arp -n "$ip" 2>/dev/null | grep "$ip" | awk '{print $3}')
        
        # Try to identify OS using TTL
        local ttl=$(ping -c 1 -W 1 "$ip" 2>/dev/null | grep "ttl=" | cut -d'=' -f4 | cut -d' ' -f1)
        local os_guess=""
        if [[ -n "$ttl" ]]; then
            if [[ $ttl -le 64 ]]; then
                os_guess="Linux/Unix"
            elif [[ $ttl -le 128 ]]; then
                os_guess="Windows"
            elif [[ $ttl -le 255 ]]; then
                os_guess="Cisco/Network Device"
            fi
        fi
        
        printf "${GREEN}[+]${NC} %-15s" "$ip"
        [[ -n "$hostname" ]] && printf " %-25s" "$hostname" || printf " %-25s" "N/A"
        [[ -n "$mac" ]] && printf " %-17s" "$mac" || printf " %-17s" "N/A"
        [[ -n "$os_guess" ]] && printf " %s" "$os_guess"
        printf "\n"
        
        # Log to file
        echo "$ip,$hostname,$mac,$os_guess,$(date)" >> "$OUTPUT_FILE"
        
        # Try common ports
        check_common_ports "$ip" &
    fi
}

# Function to check common ports on discovered hosts
check_common_ports() {
    local ip=$1
    local open_ports=""
    local common_ports=(22 23 25 53 80 135 139 443 445 993 995 3389 5985)
    
    for port in "${common_ports[@]}"; do
        if timeout 1 bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null; then
            open_ports+="$port "
        fi
    done
    
    if [[ -n "$open_ports" ]]; then
        echo "    └─ Open ports: $open_ports" | tee -a "$OUTPUT_FILE"
    fi
}

# Function to parse CIDR notation
parse_cidr() {
    local network=$1
    local ip=${network%/*}
    local prefix=${network#*/}
    
    # Convert IP to integer
    local IFS='.'
    local ip_parts=($ip)
    local ip_int=$((${ip_parts[0]} << 24 | ${ip_parts[1]} << 16 | ${ip_parts[2]} << 8 | ${ip_parts[3]}))
    
    # Calculate network and broadcast
    local mask=$((0xFFFFFFFF << (32 - prefix) & 0xFFFFFFFF))
    local network_int=$((ip_int & mask))
    local broadcast_int=$((network_int | (0xFFFFFFFF >> prefix)))
    
    # Generate IP range
    for ((i=network_int+1; i<broadcast_int; i++)); do
        local a=$(((i >> 24) & 0xFF))
        local b=$(((i >> 16) & 0xFF))
        local c=$(((i >> 8) & 0xFF))
        local d=$((i & 0xFF))
        echo "$a.$b.$c.$d"
    done
}

# Function to parse IP range
parse_range() {
    local range=$1
    local start_ip=$(echo "$range" | cut -d'-' -f1)
    local end_ip=$(echo "$range" | cut -d'-' -f2)
    
    local start_octet=$(echo "$start_ip" | cut -d'.' -f4)
    local end_octet=$(echo "$end_ip" | cut -d'.' -f4)
    local base_ip=$(echo "$start_ip" | cut -d'.' -f1-3)
    
    for ((i=start_octet; i<=end_octet; i++)); do
        echo "$base_ip.$i"
    done
}

# Main script
if [[ $# -ne 1 ]]; then
    usage
fi

TARGET=$1

echo -e "${YELLOW}=== Network Discovery Tool ===${NC}"
echo -e "${BLUE}Target:${NC} $TARGET"
echo -e "${BLUE}Output File:${NC} $OUTPUT_FILE"
echo -e "${YELLOW}=============================${NC}"
echo

# Create CSV header
echo "IP,Hostname,MAC,OS_Guess,Timestamp" > "$OUTPUT_FILE"

# Display header
printf "${YELLOW}%-15s %-25s %-17s %s${NC}\n" "IP Address" "Hostname" "MAC Address" "OS Guess"
echo "$(printf '=%.0s' {1..75})"

start_time=$(date +%s)

# Determine input type and generate IP list
if [[ "$TARGET" == *"/"* ]]; then
    # CIDR notation
    echo -e "${BLUE}[*]${NC} Scanning CIDR range: $TARGET"
    ip_list=$(parse_cidr "$TARGET")
elif [[ "$TARGET" == *"-"* ]]; then
    # IP range
    echo -e "${BLUE}[*]${NC} Scanning IP range: $TARGET"
    ip_list=$(parse_range "$TARGET")
else
    # Single IP
    echo -e "${BLUE}[*]${NC} Scanning single host: $TARGET"
    ip_list="$TARGET"
fi

# Ping sweep
echo -e "${BLUE}[*]${NC} Starting host discovery..."

for ip in $ip_list; do
    ping_host "$ip" &
    
    # Limit concurrent processes
    (($(jobs -r | wc -l) >= 50)) && wait
done

# Wait for all processes to complete
wait

end_time=$(date +%s)
scan_time=$((end_time - start_time))

echo
echo -e "${YELLOW}[*]${NC} Discovery completed in ${scan_time}s"
echo -e "${BLUE}[*]${NC} Results saved to $OUTPUT_FILE"

# Summary
total_hosts=$(grep -c "^[0-9]" "$OUTPUT_FILE")
if [[ $total_hosts -gt 1 ]]; then
    echo -e "${GREEN}[+]${NC} Found $((total_hosts-1)) active hosts"
else
    echo -e "${RED}[-]${NC} No active hosts found"
fi
