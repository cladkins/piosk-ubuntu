#!/bin/bash
# Multi-screen runner - starts separate browser on each display

echo "Starting PiOSK multi-screen mode..."

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Directory for screen configs
SCREEN_DIR="$PROJECT_ROOT/screens"
mkdir -p "$SCREEN_DIR"

# Get available displays
DISPLAYS=$("$SCRIPT_DIR/detect-displays.sh")

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
    
    # Start browser on this display
    echo "Starting browser on $DISPLAY_ID with URLs: $URLS"
    DISPLAY="$DISPLAY_ID" nohup snap run chromium \
        --kiosk \
        --remote-debugging-port=$PORT \
        --user-data-dir="/tmp/piosk-$DISPLAY_ID" \
        $URLS > "/tmp/piosk-$DISPLAY_ID.log" 2>&1 &
    
    # Save PID for later management
    echo $! > "/tmp/piosk-$DISPLAY_ID.pid"
    
    PORT=$((PORT + 1))
done

echo "Multi-screen mode started successfully"