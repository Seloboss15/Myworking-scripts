
#!/bin/bash

# System Security Audit Script
# Description: Comprehensive system security audit
# Usage: ./system_audit.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

AUDIT_FILE="system_audit_$(hostname)_$(date +%Y%m%d_%H%M%S).txt"

# Function to print section headers
print_header() {
    echo -e "\n${YELLOW}=== $1 ===${NC}" | tee -a "$AUDIT_FILE"
}

# Function to print findings with severity levels
print_finding() {
    local level=$1
    local message=$2
    local color
    
    case $level in
        "HIGH") color=$RED ;;
        "MEDIUM") color=$YELLOW ;;
        "LOW") color=$BLUE ;;
        "INFO") color=$GREEN ;;
        *) color=$NC ;;
    esac
    
    echo -e "${color}[$level]${NC} $message" | tee -a "$AUDIT_FILE"
}

# System Information
audit_system_info() {
    print_header "SYSTEM INFORMATION"
    
    echo "Hostname: $(hostname)" | tee -a "$AUDIT_FILE"
    echo "OS: $(grep PRETTY_NAME /etc/os-release | cut -d'=' -f2 | tr -d '"')" | tee -a "$AUDIT_FILE"
    echo "Kernel: $(uname -r)" | tee -a "$AUDIT_FILE"
    echo "Architecture: $(uname -m)" | tee -a "$AUDIT_FILE"
    echo "Uptime: $(uptime -p)" | tee -a "$AUDIT_FILE"
    echo "Date: $(date)" | tee -a "$AUDIT_FILE"
}

# User Account Audit
audit_users() {
    print_header "USER ACCOUNT AUDIT"
    
    # Check for users with UID 0
    root_users=$(awk -F: '$3 == 0 {print $1}' /etc/passwd)
    if [[ $(echo $root_users | wc -w) -gt 1 ]]; then
        print_finding "HIGH" "Multiple users with UID 0 found: $root_users"
    else
        print_finding "INFO" "Only root user has UID 0"
    fi
    
    # Check for users with empty passwords
    empty_pass=$(awk -F: '($2 == "" || $2 == "*" || $2 == "!" ) {print $1}' /etc/shadow 2>/dev/null)
    if [[ -n "$empty_pass" ]]; then
        print_finding "HIGH" "Users with empty or disabled passwords: $empty_pass"
    else
        print_finding "INFO" "No users with empty or disabled passwords found"
    fi
    
    # List user accounts with UID >= 1000 (regular users)
    print_finding "INFO" "Regular user accounts (UID >= 1000):"
    awk -F: '($3 >= 1000) {print $1}' /etc/passwd | tee -a "$AUDIT_FILE"
    
    # Check sudo access
    if [[ -f /etc/sudoers ]]; then
        print_finding "INFO" "Sudo configuration (excluding comments):"
        grep -vE '^\s*#|^\s*$' /etc/sudoers 2>/dev/null | tee -a "$AUDIT_FILE"
    fi
}

# Network Configuration Audit
audit_network() {
    print_header "NETWORK CONFIGURATION"
    
    # Check listening services
    print_finding "INFO" "Listening services:"
    if command -v ss >/dev/null; then
        ss -tuln | tee -a "$AUDIT_FILE"
    else
        netstat -tuln 2>/dev/null | tee -a "$AUDIT_FILE"
    fi
    
    # Active network connections
    active_connections=$(ss -tn 2>/dev/null | grep ESTAB | wc -l)
    print_finding "INFO" "Active network connections: $active_connections"
    
    # Check firewall status
    if command -v ufw >/dev/null; then
        ufw_status=$(ufw status 2>/dev/null | head -1)
        if [[ "$ufw_status" == *inactive* ]]; then
            print_finding "MEDIUM" "UFW firewall is inactive"
        else
            print_finding "INFO" "UFW firewall status: $ufw_status"
        fi
    elif command -v iptables >/dev/null; then
        iptables_rules=$(iptables -L 2>/dev/null | wc -l)
        if [[ $iptables_rules -le 8 ]]; then
            print_finding "MEDIUM" "No iptables rules configured"
        else
            print_finding "INFO" "Iptables rules present ($iptables_rules lines)"
        fi
    else
        print_finding "INFO" "No firewall tools (ufw or iptables) found"
    fi
}

# File System Audit
audit_filesystem() {
    print_header "FILE SYSTEM AUDIT"
    
    # SUID/SGID files
    print_finding "INFO" "SUID/SGID files (top 20):"
    find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -exec ls -ld {} + 2>/dev/null | head -20 | tee -a "$AUDIT_FILE"
    
    # World-writable files
    world_writable=$(find / -xdev -type f -perm -002 2>/dev/null | head -10)
    if [[ -n "$world_writable" ]]; then
        print_finding "MEDIUM" "World-writable files found:"
        echo "$world_writable" | tee -a "$AUDIT_FILE"
    else
        print_finding "INFO" "No world-writable files found"
    fi
    
    # Files with no owner or group
    no_owner=$(find / -xdev \( -nouser -o -nogroup \) 2>/dev/null | head -10)
    if [[ -n "$no_owner" ]]; then
        print_finding "MEDIUM" "Files with no owner or group:"
        echo "$no_owner" | tee -a "$AUDIT_FILE"
    else
        print_finding "INFO" "No files without owner or group found"
    fi
    
    # Disk usage
    print_finding "INFO" "Disk usage:"
    df -h | tee -a "$AUDIT_FILE"
    
    # Large files in /tmp
    print_finding "INFO" "Largest files in /tmp:"
    find /tmp -type f -exec ls -lh {} + 2>/dev/null | sort -k5 -hr | head -5 | tee -a "$AUDIT_FILE"
}

# Process Audit
audit_processes() {
    print_header "PROCESS AUDIT"
    
    print_finding "INFO" "Top processes by CPU usage:"
    ps aux --sort=-%cpu | head -10 | tee -a "$AUDIT_FILE"
    
    print_finding "INFO" "Top processes by Memory usage:"
    ps aux --sort=-%mem | head -10 | tee -a "$AUDIT_FILE"
    
    suspicious_procs=$(ps aux | grep -E "(nc|ncat|socat|perl|python|ruby|php)" | grep -v grep)
    if [[ -n "$suspicious_procs" ]]; then
        print_finding "MEDIUM" "Potentially suspicious processes detected:"
        echo "$suspicious_procs" | tee -a "$AUDIT_FILE"
    else
        print_finding "INFO" "No suspicious processes detected"
    fi
}

# Log File Audit
audit_logs() {
    print_header "LOG FILE AUDIT"
    
    if [[ -f /var/log/auth.log ]]; then
        failed_logins=$(grep "Failed password" /var/log/auth.log | tail -10)
        if [[ -n "$failed_logins" ]]; then
            print_finding "MEDIUM" "Recent failed login attempts:"
            echo "$failed_logins" | tee -a "$AUDIT_FILE"
        else
            print_finding "INFO" "No recent failed login attempts found"
        fi
        
        ssh_attacks=$(grep "sshd.*Failed" /var/log/auth.log | awk '{print $11}' | sort | uniq -c | sort -nr | head -5)
        if [[ -n "$ssh_attacks" ]]; then
            print_finding "HIGH" "SSH brute force attempts (top sources):"
            echo "$ssh_attacks" | tee -a "$AUDIT_FILE"
        else
            print_finding "INFO" "No SSH brute force attempts detected"
        fi
    else
        print_finding "INFO" "/var/log/auth.log not found"
    fi
    
    if [[ -f /var/log/syslog ]]; then
        recent_errors=$(grep -iE "error|critical|fatal" /var/log/syslog | tail -5)
        if [[ -n "$recent_errors" ]]; then
            print_finding "MEDIUM" "Recent system errors:"
            echo "$recent_errors" | tee -a "$AUDIT_FILE"
        else
           
