#!/bin/bash
# Multi-screen runner - starts separate browser on each display

echo "Starting PiOSK multi-screen mode..."

# Directory for screen configs
SCREEN_DIR="/opt/piosk/screens"
mkdir -p "$SCREEN_DIR"

# Get available displays
DISPLAYS=$(/opt/piosk/scripts/detect-displays.sh)

# Counter for debug ports
PORT=9222

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