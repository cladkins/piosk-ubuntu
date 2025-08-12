#!/bin/bash
# Multi-screen runner - starts separate browser on each display

# Enhanced logging
LOG_FILE="/tmp/piosk-multiscreen.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

echo "$(date): Starting PiOSK multi-screen mode..."
echo "$(date): Running as user: $(whoami)"
echo "$(date): Current working directory: $(pwd)"
echo "$(date): Environment variables:"
echo "$(date):   USER=$USER"
echo "$(date):   HOME=$HOME"
echo "$(date):   DISPLAY=$DISPLAY"
echo "$(date):   XAUTHORITY=$XAUTHORITY"

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
echo "$(date): Detecting displays using: $SCRIPT_DIR/detect-displays.sh"
DISPLAYS=$("$SCRIPT_DIR/detect-displays.sh")
echo "$(date): Display detection result: '$DISPLAYS'"

if [ -z "$DISPLAYS" ]; then
    echo "$(date): Warning: No displays detected, using :0 as fallback"
    DISPLAYS=":0"
fi

echo "$(date): Final display list: $DISPLAYS"

# First, stop any existing single-screen chromium
pkill -f "chromium.*remote-debugging-port" 2>/dev/null || true
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
    echo "$(date): Starting browser on $DISPLAY_ID with URLs: $URLS"
    
    # Use the EXACT same approach as the working single-screen script
    REAL_USER=$(who | awk 'NR==1{print $1}')
    REAL_HOME=$(eval echo ~$REAL_USER)
    
    # Find the actual X authority file (Wayland vs X11)
    USER_ID=$(id -u $REAL_USER)
    if [ -f "/run/user/$USER_ID/.mutter-Xwaylandauth"* ]; then
        XAUTH_FILE=$(find /run/user/$USER_ID -name ".mutter-Xwaylandauth*" 2>/dev/null | head -1)
    else
        XAUTH_FILE="$REAL_HOME/.Xauthority"  # fallback
    fi
    
    echo "$(date): Found X authority file: $XAUTH_FILE"
    
    echo "$(date): Starting browser on $DISPLAY_ID with URLs: $URLS"
    echo "$(date): Using same method as working single-screen script"
    
    # Position browsers on different monitors - EXACT working version
    if [ "$DISPLAY_ID" = ":0" ]; then
        # First monitor - no extra flags
        EXTRA_FLAGS=""
    else
        # Second monitor - position it on second screen
        EXTRA_FLAGS="--new-window --window-position=1920,0"
    fi
    
    echo "$(date): Extra flags for $DISPLAY_ID: $EXTRA_FLAGS"
    
    sudo -u "$REAL_USER" DISPLAY=:0 XAUTHORITY="$XAUTH_FILE" snap run chromium \
        --start-fullscreen \
        --start-maximized \
        --disable-infobars \
        --disable-extensions \
        --disable-plugins \
        --disable-translate \
        --disable-default-apps \
        --no-first-run \
        --disable-session-crashed-bubble \
        --remote-debugging-port=$PORT \
        --user-data-dir="/tmp/piosk-$DISPLAY_ID" \
        $EXTRA_FLAGS \
        $URLS > "/tmp/piosk-$DISPLAY_ID.log" 2>&1 &
    
    CHROMIUM_PID=$!
    
    # Save PID for later management  
    echo $CHROMIUM_PID > "/tmp/piosk-$DISPLAY_ID.pid"
    echo "$(date): Chromium started with PID: $CHROMIUM_PID"
    
    # Give it a moment to start and check if it's still running
    sleep 3
    if kill -0 $CHROMIUM_PID 2>/dev/null; then
        echo "$(date): Chromium process $CHROMIUM_PID is running successfully on $DISPLAY_ID"
        
        # Force fullscreen for this specific window - simple approach
        echo "$(date): Forcing fullscreen for $DISPLAY_ID (PID: $CHROMIUM_PID)"
        
        # Wait a bit longer for window to be fully ready
        sleep 2
        
        # Find and activate this specific window
        WINDOW_ID=$(sudo -u "$REAL_USER" DISPLAY=:0 XAUTHORITY="$XAUTH_FILE" xdotool search --onlyvisible --pid $CHROMIUM_PID 2>/dev/null | head -1)
        
        if [ -n "$WINDOW_ID" ]; then
            echo "$(date): Found window ID: $WINDOW_ID for PID: $CHROMIUM_PID"
            # Simple F11 press only
            sudo -u "$REAL_USER" DISPLAY=:0 XAUTHORITY="$XAUTH_FILE" xdotool windowactivate --sync $WINDOW_ID key F11 2>/dev/null || true
        else
            echo "$(date): Could not find window ID for PID: $CHROMIUM_PID"
        fi
    else
        echo "$(date): ERROR: Chromium process $CHROMIUM_PID exited immediately on $DISPLAY_ID"
        echo "$(date): Chromium log output:"
        cat "/tmp/piosk-$DISPLAY_ID.log" | sed "s/^/$(date): /"
    fi
    
    PORT=$((PORT + 1))
    
    # Add longer delay between browser starts to prevent conflicts and allow fullscreen to work
    sleep 5
done

echo "$(date): Multi-screen mode startup completed"