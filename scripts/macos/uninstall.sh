#!/bin/bash
# LaskoBOT macOS Uninstaller

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="${LASKOBOT_INSTALL_DIR:-$HOME/.local/lib/laskobot}"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.laskobot.daemon.plist"

echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        LaskoBOT macOS Uninstaller            ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Stop service
echo -e "${CYAN}[1/3] Stopping service...${NC}"
if launchctl list | grep -q "com.laskobot.daemon"; then
    launchctl unload "$LAUNCH_AGENTS_DIR/$PLIST_NAME" 2>/dev/null || true
    echo -e "${GREEN}✓ Service stopped${NC}"
else
    echo -e "${YELLOW}Service not running${NC}"
fi

# Step 2: Remove plist
echo ""
echo -e "${CYAN}[2/3] Removing launchd plist...${NC}"
if [ -f "$LAUNCH_AGENTS_DIR/$PLIST_NAME" ]; then
    rm -f "$LAUNCH_AGENTS_DIR/$PLIST_NAME"
    echo -e "${GREEN}✓ Removed $PLIST_NAME${NC}"
else
    echo -e "${YELLOW}Plist not found${NC}"
fi

# Step 3: Remove installation
echo ""
echo -e "${CYAN}[3/3] Removing installation...${NC}"
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo -e "${GREEN}✓ Removed $INSTALL_DIR${NC}"
else
    echo -e "${YELLOW}Installation directory not found${NC}"
fi

# Cleanup logs
rm -f /tmp/laskobot.log /tmp/laskobot.err 2>/dev/null || true

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Uninstallation Complete!             ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} Remember to remove the Chrome extension manually"
echo "      Go to chrome://extensions and remove LaskoBOT"
