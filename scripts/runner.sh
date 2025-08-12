#!/bin/bash

# Simple runner that uses the working command
echo "Starting PiOSK kiosk mode..."

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if Chromium is installed
if ! command -v snap >/dev/null 2>&1; then
    echo "Error: snap is not installed"
    exit 1
fi

if ! snap list chromium >/dev/null 2>&1; then
    echo "Error: Chromium snap is not installed. Please install with: sudo snap install chromium"
    exit 1
fi

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is not installed. Please install with: sudo apt install jq"
    exit 1
fi

# Get URLs from config file
URLS=$(jq -r '.urls | map(.url) | join(" ")' "$PROJECT_ROOT/config.json")

if [ -z "$URLS" ] || [ "$URLS" = "null" ]; then
    echo "Error: No URLs found in config.json"
    exit 1
fi

echo "Starting Chromium with URLs: $URLS"

# Find the actual logged-in user and their X authority
REAL_USER=$(who | awk 'NR==1{print $1}')
REAL_HOME=$(eval echo ~$REAL_USER)

# Find the actual X authority file (Wayland vs X11)
USER_ID=$(id -u $REAL_USER)
if [ -f "/run/user/$USER_ID/.mutter-Xwaylandauth"* ]; then
    XAUTH_FILE=$(find /run/user/$USER_ID -name ".mutter-Xwaylandauth*" 2>/dev/null | head -1)
else
    XAUTH_FILE="$REAL_HOME/.Xauthority"  # fallback
fi

echo "Found X authority file: $XAUTH_FILE"

# Use snap Chromium with remote debugging enabled, run as proper user
exec sudo -u "$REAL_USER" DISPLAY=:0 XAUTHORITY="$XAUTH_FILE" snap run chromium --kiosk --remote-debugging-port=9222 --no-sandbox $URLS