# Security Analyst Scripts Repository

A comprehensive collection of security analysis scripts for penetration testing, network reconnaissance, log analysis, and incident response. This repository contains 30 practical scripts designed for security professionals and analysts.

## 📁 Repository Structure

```
├── bash_scripts/          # 20 Bash scripts for various security tasks
├── python_scripts/        # 10 Python scripts for advanced analysis
├── README.md             # This file
└── requirements.txt      # Python dependencies
```

## 🛡️ Bash Scripts (20)

### Network & Reconnaissance
1. **port_scanner.sh** - TCP port scanner with service detection
2. **network_discovery.sh** - Network host discovery and enumeration
3. **subdomain_enum.sh** - Subdomain enumeration using multiple methods
4. **dns_enum.sh** - DNS record enumeration and analysis
5. **ssl_cert_check.sh** - SSL certificate analysis and vulnerability check

### System Analysis
6. **system_audit.sh** - Complete system security audit
7. **process_monitor.sh** - Real-time process monitoring and analysis
8. **file_integrity.sh** - File integrity monitoring with checksums
9. **user_audit.sh** - User account and privilege analysis
10. **service_enum.sh** - Running services enumeration and analysis

### Log Analysis
11. **log_analyzer.sh** - Multi-format log file analysis
12. **failed_login_detector.sh** - Detect failed login attempts
13. **suspicious_activity.sh** - Monitor for suspicious system activity
14. **auth_log_parser.sh** - Authentication log parser and analyzer

### Security Testing
15. **web_vuln_scanner.sh** - Basic web application vulnerability scanner
16. **brute_force_detector.sh** - Detect brute force attack patterns
17. **malware_scanner.sh** - Simple malware detection using signatures
18. **backup_security.sh** - Backup file security checker

### Utilities
19. **incident_response.sh** - Incident response data collection
20. **security_report.sh** - Generate comprehensive security reports

## 🐍 Python Scripts (10)

### Network Security
1. **advanced_port_scanner.py** - Multi-threaded port scanner with banner grabbing
2. **packet_analyzer.py** - Network packet capture and analysis
3. **vulnerability_scanner.py** - Automated vulnerability assessment tool

### Log Analysis & SIEM
4. **log_correlator.py** - Advanced log correlation and pattern detection
5. **threat_hunter.py** - Threat hunting with IOC matching
6. **siem_connector.py** - SIEM integration and alert management

### Forensics & Analysis
7. **hash_analyzer.py** - File hash analysis and malware detection
8. **memory_analyzer.py** - Memory dump analysis for artifacts
9. **timeline_generator.py** - Digital forensics timeline creation

### Automation
10. **security_automation.py** - Automated security task orchestration

## 🚀 Installation & Setup

### Prerequisites
- Bash 4.0+ (for bash scripts)
- Python 3.7+ (for python scripts)
- Required system tools: nmap, dig, curl, netstat, ss, etc.

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/seloboss15/Myworking-scripts.git
   cd Myworking-scripts
   ```

2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Make bash scripts executable:
   ```bash
   chmod +x bash_scripts/*.sh
   ```

## 📖 Usage Examples

### Bash Scripts
```bash
# Network discovery
./bash_scripts/network_discovery.sh 192.168.1.0/24

# Port scanning
./bash_scripts/port_scanner.sh 192.168.1.100

# System audit
./bash_scripts/system_audit.sh
```

### Python Scripts
```bash
# Advanced port scanning
python3 python_scripts/advanced_port_scanner.py -t 192.168.1.100 -p 1-1000

# Log analysis
python3 python_scripts/log_correlator.py -f /var/log/auth.log

# Vulnerability scanning
python3 python_scripts/vulnerability_scanner.py -t example.com
```

## ⚠️ Important Notes

- **Educational Purpose**: These scripts are for educational and authorized testing only
- **Authorization Required**: Only use on systems you own or have explicit permission to test
- **Responsible Disclosure**: Report vulnerabilities through proper channels
- **Legal Compliance**: Ensure compliance with local laws and regulations

## 🔧 Requirements

### System Tools
- nmap
- dig/nslookup
- curl/wget
- netstat/ss
- awk/sed/grep
- openssl

### Python Libraries
- requests
- scapy
- psutil
- colorama
- python-nmap
- yara-python

## 📋 Features

### Bash Scripts Features
- ✅ Comprehensive network reconnaissance
- ✅ System security auditing
- ✅ Log analysis and monitoring
- ✅ Incident response automation
- ✅ Vulnerability detection
- ✅ Report generation

### Python Scripts Features
- ✅ Advanced network analysis
- ✅ Multi-threaded operations
- ✅ Machine learning integration
- ✅ Database connectivity
- ✅ API integrations
- ✅ Automated reporting



## ⚠️ Disclaimer

These tools are provided for educational and authorized security testing purposes only. Users are responsible for complying with applicable laws and obtaining proper authorization before using these scripts. The author is not responsible for any misuse or damage caused by these tools.

## 📞 Contact

- **Author**: Selome Asokere
- **Email**: seloboss15@outlook.com
- **LinkedIn**:www.linkedin.com/in/asokereselome

---

**⭐ If you find this repository helpful, please consider giving it a star!**
