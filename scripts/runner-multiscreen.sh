#!/bin/bash
# Multi-screen runner - starts separate browser on each display

echo "Starting PiOSK multi-screen mode..."

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

# Directory for screen configs
SCREEN_DIR="$PROJECT_ROOT/screens"
mkdir -p "$SCREEN_DIR"

# Get available displays
DISPLAYS=$("$SCRIPT_DIR/detect-displays.sh")

if [ -z "$DISPLAYS" ]; then
    echo "Warning: No displays detected, using :0 as fallback"
    DISPLAYS=":0"
fi

# First, stop any existing single-screen chromium
pkill -f "chromium.*kiosk" 2>/dev/null || true
sleep 2

# Counter for debug ports (avoid conflict with single-screen mode)
PORT=9223

# Start browser on each display
for DISPLAY_ID in $DISPLAYS; do
    SCREEN_CONFIG="$SCREEN_DIR/${DISPLAY_ID}.json"
    
    # Create default config if it doesn't exist
    if [ ! -f "$SCREEN_CONFIG" ]; then
        cat > "$SCREEN_CONFIG" << EOF
{
  "urls": [
    {"url": "https://time.is"},
    {"url": "https://weather.com"}
  ]
}
EOF
    fi
    
    # Get URLs for this screen
    URLS=$(jq -r '.urls | map(.url) | join(" ")' "$SCREEN_CONFIG")
    
    # Start browser on this display with proper X11 authorization
    echo "Starting browser on $DISPLAY_ID with URLs: $URLS"
    
    # Run as the logged-in user with proper X11 access
    sudo -u $USER DISPLAY="$DISPLAY_ID" XAUTHORITY="$HOME/.Xauthority" nohup snap run chromium \
        --kiosk \
        --remote-debugging-port=$PORT \
        --user-data-dir="/tmp/piosk-$DISPLAY_ID" \
        --no-sandbox \
        $URLS > "/tmp/piosk-$DISPLAY_ID.log" 2>&1 &
    
    # Save PID for later management
    echo $! > "/tmp/piosk-$DISPLAY_ID.pid"
    
    PORT=$((PORT + 1))
done

echo "Multi-screen mode started successfully"