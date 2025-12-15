#!/bin/bash
# LaskoBOT macOS Installer
# Installs launchd service for auto-start on login

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
INSTALL_DIR="${LASKOBOT_INSTALL_DIR:-$HOME/.local/lib/laskobot}"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.laskobot.daemon.plist"

echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        LaskoBOT macOS Installer              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed${NC}"
    echo "Install Node.js 20+ from https://nodejs.org or via Homebrew: brew install node"
    exit 1
fi

NODE_PATH=$(which node)
NODE_BIN_DIR=$(dirname "$NODE_PATH")
NODE_VERSION=$(node -v)

echo -e "${GREEN}✓ Node.js found: $NODE_VERSION${NC}"
echo "  Path: $NODE_PATH"

# Step 1: Build if needed
echo ""
echo -e "${CYAN}[1/4] Building...${NC}"
cd "$PROJECT_DIR"

if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

if [ ! -f "dist/index-unified.js" ]; then
    echo "Building..."
    npm run build
else
    echo -e "${GREEN}✓ Already built${NC}"
fi

# Step 2: Copy to install directory
echo ""
echo -e "${CYAN}[2/4] Installing to $INSTALL_DIR...${NC}"
mkdir -p "$INSTALL_DIR"

# Copy dist and package files
cp -r dist "$INSTALL_DIR/"
cp package.json "$INSTALL_DIR/"
cp package-lock.json "$INSTALL_DIR/" 2>/dev/null || true

# Install production dependencies only
cd "$INSTALL_DIR"
npm install --omit=dev 2>/dev/null || npm install --production

echo -e "${GREEN}✓ Installed to $INSTALL_DIR${NC}"

# Step 3: Create launchd plist
echo ""
echo -e "${CYAN}[3/4] Creating launchd service...${NC}"
mkdir -p "$LAUNCH_AGENTS_DIR"

# Process template
sed -e "s|__NODE_PATH__|$NODE_PATH|g" \
    -e "s|__INSTALL_DIR__|$INSTALL_DIR|g" \
    -e "s|__NODE_BIN_DIR__|$NODE_BIN_DIR|g" \
    "$SCRIPT_DIR/$PLIST_NAME" > "$LAUNCH_AGENTS_DIR/$PLIST_NAME"

echo -e "${GREEN}✓ Created $LAUNCH_AGENTS_DIR/$PLIST_NAME${NC}"

# Step 4: Load the service
echo ""
echo -e "${CYAN}[4/4] Loading service...${NC}"

# Unload if already loaded
launchctl unload "$LAUNCH_AGENTS_DIR/$PLIST_NAME" 2>/dev/null || true

# Load the new service
launchctl load "$LAUNCH_AGENTS_DIR/$PLIST_NAME"

# Wait and check status
sleep 2

if launchctl list | grep -q "com.laskobot.daemon"; then
    echo -e "${GREEN}✓ Service loaded and running${NC}"
else
    echo -e "${YELLOW}⚠ Service loaded but may not be running yet${NC}"
    echo "Check logs: tail -f /tmp/laskobot.log /tmp/laskobot.err"
fi

# Summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Installation Complete!               ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}WebSocket server:${NC} ws://localhost:8765"
echo -e "${CYAN}Logs:${NC} /tmp/laskobot.log, /tmp/laskobot.err"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Install the Chrome extension from: $PROJECT_DIR/chrome-extension"
echo "     Go to chrome://extensions → Developer mode → Load unpacked"
echo ""
echo "  2. Add to Claude Code MCP config:"
echo '     {
       "mcpServers": {
         "laskobot": {
           "type": "http",
           "url": "http://127.0.0.1:3000/mcp"
         }
       }
     }'
echo ""
echo -e "${CYAN}Management commands:${NC}"
echo "  Stop:    launchctl unload ~/Library/LaunchAgents/$PLIST_NAME"
echo "  Start:   launchctl load ~/Library/LaunchAgents/$PLIST_NAME"
echo "  Restart: launchctl kickstart -k gui/\$(id -u)/com.laskobot.daemon"
echo "  Logs:    tail -f /tmp/laskobot.log"
