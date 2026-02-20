#!/bin/bash

# ========= Colors =========
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ========= Check if figlet is installed =========
if ! command -v figlet &> /dev/null; then
    echo -e "${RED}[!] figlet is not installed. Please install it to display large fonts.${NC}"
    exit 1
fi

# ========= Animated "Initializing..." =========
clear

echo -e "${BLUE}"
echo "======================================="
echo "            Loading Tool"
echo "======================================="
echo -e "${NC}"

echo -ne "${YELLOW}Initializing ${NC}"

spinner() {
    local pid=$!
    local spin='-\|/'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\b${CYAN}${spin:$i:1}${NC}"
        sleep 0.1
    done
}

# Fake loading delay for animation (simulate work)
sleep 2 &
spinner
wait

clear

# ========= Large Font "subfinder R3" =========
echo -e "${BLUE}"
figlet -f slant "subfinder R3"
echo -e "${NC}"

# ========= Ask for Input =========
read -p "Enter target domain (example.com): " DOMAIN

# Validate input
if [ -z "$DOMAIN" ]; then
    echo -e "${RED}[!] Domain cannot be empty. Exiting...${NC}"
    exit 1
fi

# ========= Check Required Tools =========
for tool in assetfinder httprobe; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}[!] $tool is not installed.${NC}"
        exit 1
    fi
done

# ========= Create Output Directory =========
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="subdomain_scan_${DOMAIN}_$TIMESTAMP"
mkdir -p "$OUTPUT_DIR"

echo ""
echo -e "${CYAN}[+] Target: $DOMAIN${NC}"
echo -e "${CYAN}[+] Saving results to: $OUTPUT_DIR${NC}"
echo ""

# ========= Subdomain Enumeration =========
echo -e "${YELLOW}[+] Finding subdomains...${NC}"
assetfinder --subs-only "$DOMAIN" | sort -u > "$OUTPUT_DIR/subdomains.txt"

COUNT=$(wc -l < "$OUTPUT_DIR/subdomains.txt")

if [ "$COUNT" -eq 0 ]; then
    echo -e "${RED}[!] No subdomains found.${NC}"
    exit 1
fi

echo -e "${GREEN}[✔] Found $COUNT subdomains.${NC}"

# ========= Alive Check =========
echo -e "${YELLOW}[+] Checking alive subdomains...${NC}"
httprobe < "$OUTPUT_DIR/subdomains.txt" > "$OUTPUT_DIR/alive.txt"

ALIVE_COUNT=$(wc -l < "$OUTPUT_DIR/alive.txt")
echo -e "${GREEN}[✔] $ALIVE_COUNT subdomains are alive.${NC}"

# ========= Display Subdomains and Alive Subdomains =========
echo -e "\n${CYAN}========== Subdomains Found ==========${NC}"
cat "$OUTPUT_DIR/subdomains.txt"

echo -e "\n${CYAN}========== Alive Subdomains ==========${NC}"
cat "$OUTPUT_DIR/alive.txt"

# ========= Finish =========
echo ""
echo -e "${BLUE}========== Scan Completed ==========${NC}"
echo -e "${GREEN}Subdomains saved to: $OUTPUT_DIR/subdomains.txt${NC}"
echo -e "${GREEN}Alive subdomains saved to: $OUTPUT_DIR/alive.txt${NC}"
echo ""

