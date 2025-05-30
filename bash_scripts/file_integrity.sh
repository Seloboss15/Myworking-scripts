#!/bin/bash
# file_integrity.sh
# File Integrity Monitoring with checksums (SHA256)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Directory to monitor (default to current directory)
MONITOR_DIR="${1:-.}"

# Baseline checksum file
BASELINE_FILE="file_integrity_baseline.sha256"

echo -e "${YELLOW}Starting File Integrity Check on directory: $MONITOR_DIR${NC}"
echo "Timestamp: $(date)"
echo "----------------------------------------"

# Check if baseline file exists
if [[ ! -f "$BASELINE_FILE" ]]; then
    echo -e "${GREEN}Baseline file not found. Creating baseline...${NC}"
    # Create baseline file with SHA256 checksums of all files recursively
    find "$MONITOR_DIR" -type f -exec sha256sum {} + > "$BASELINE_FILE"
    echo -e "${GREEN}Baseline created at $BASELINE_FILE.${NC}"
    exit 0
fi

# Create current checksum snapshot
CURRENT_FILE="current_checksums.sha256"
find "$MONITOR_DIR" -type f -exec sha256sum {} + > "$CURRENT_FILE"

# Compare baseline and current
echo -e "${YELLOW}Comparing current file checksums against baseline...${NC}"

# Files changed or new
CHANGED=$(comm -23 <(sort "$CURRENT_FILE") <(sort "$BASELINE_FILE"))
# Files deleted or missing
DELETED=$(comm -13 <(sort "$CURRENT_FILE") <(sort "$BASELINE_FILE"))

if [[ -z "$CHANGED" && -z "$DELETED" ]]; then
    echo -e "${GREEN}No changes detected in monitored files.${NC}"
else
    if [[ -n "$CHANGED" ]]; then
        echo -e "${RED}Modified or New Files:${NC}"
        echo "$CHANGED" | awk '{print $2}'
    fi

    if [[ -n "$DELETED" ]]; then
        echo -e "${RED}Deleted Files:${NC}"
        echo "$DELETED" | awk '{print $2}'
    fi
fi

# Clean up current snapshot file
rm "$CURRENT_FILE"
