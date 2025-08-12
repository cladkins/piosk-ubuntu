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
    echo "$(date): Starting browser on $DISPLAY_ID with URLs: $URLS"
    
    # Find the actual logged-in user and their X authority
    REAL_USER=$(who | awk 'NR==1{print $1}')
    REAL_HOME=$(eval echo ~$REAL_USER)
    
    # Try multiple locations for X authority file
    if [ -f "$REAL_HOME/.Xauthority" ]; then
        XAUTH_FILE="$REAL_HOME/.Xauthority"
    elif [ -f "/tmp/.X11-unix/X0" ] && [ -f "/run/user/$(id -u $REAL_USER)/gdm/Xauthority" ]; then
        XAUTH_FILE="/run/user/$(id -u $REAL_USER)/gdm/Xauthority"
    elif [ -f "/var/lib/gdm3/:0.Xauth" ]; then
        XAUTH_FILE="/var/lib/gdm3/:0.Xauth"
    else
        # Try to find any Xauthority file
        XAUTH_FILE=$(find /tmp /run -name "*Xauth*" -o -name "*xauth*" 2>/dev/null | head -1)
        if [ -z "$XAUTH_FILE" ]; then
            XAUTH_FILE="$REAL_HOME/.Xauthority"  # fallback
        fi
    fi
    
    echo "$(date): User detection results:"
    echo "$(date):   REAL_USER=$REAL_USER"
    echo "$(date):   REAL_HOME=$REAL_HOME"
    echo "$(date):   XAUTH_FILE=$XAUTH_FILE"
    echo "$(date):   XAUTH_FILE exists: $([ -f "$XAUTH_FILE" ] && echo "YES" || echo "NO")"
    
    # Check if we can access X11
    echo "$(date): Testing X11 access..."
    sudo -u "$REAL_USER" DISPLAY="$DISPLAY_ID" XAUTHORITY="$XAUTH_FILE" xset q > /tmp/x11-test-$DISPLAY_ID.log 2>&1
    if [ $? -eq 0 ]; then
        echo "$(date): X11 access test PASSED for $DISPLAY_ID"
    else
        echo "$(date): X11 access test FAILED for $DISPLAY_ID"
        echo "$(date): X11 test output:"
        cat /tmp/x11-test-$DISPLAY_ID.log | sed "s/^/$(date): /"
    fi
    
    # Try alternative approach - run through user's systemd session
    echo "$(date): Launching Chromium with command:"
    echo "$(date):   Method 1: sudo -u \"$REAL_USER\" DISPLAY=\"$DISPLAY_ID\" XAUTHORITY=\"$XAUTH_FILE\""
    
    # First try: Direct sudo with X authority
    sudo -u "$REAL_USER" DISPLAY="$DISPLAY_ID" XAUTHORITY="$XAUTH_FILE" nohup snap run chromium \
        --kiosk \
        --remote-debugging-port=$PORT \
        --user-data-dir="/tmp/piosk-$DISPLAY_ID" \
        --no-sandbox \
        $URLS > "/tmp/piosk-$DISPLAY_ID.log" 2>&1 &
    
    CHROMIUM_PID=$!
    
    # If that fails quickly, try running through the user's session
    sleep 1
    if ! kill -0 $CHROMIUM_PID 2>/dev/null; then
        echo "$(date): Method 1 failed, trying Method 2: systemd-run --uid"
        systemd-run --uid="$REAL_USER" --gid="$(id -g $REAL_USER)" --setenv=DISPLAY="$DISPLAY_ID" --setenv=XAUTHORITY="$XAUTH_FILE" \
            snap run chromium --kiosk --remote-debugging-port=$PORT --user-data-dir="/tmp/piosk-$DISPLAY_ID" --no-sandbox $URLS \
            > "/tmp/piosk-$DISPLAY_ID.log" 2>&1 &
        CHROMIUM_PID=$!
    fi
    
    # Save PID for later management  
    echo $CHROMIUM_PID > "/tmp/piosk-$DISPLAY_ID.pid"
    echo "$(date): Chromium started with PID: $CHROMIUM_PID"
    
    # Give it a moment to start and check if it's still running
    sleep 2
    if kill -0 $CHROMIUM_PID 2>/dev/null; then
        echo "$(date): Chromium process $CHROMIUM_PID is running successfully on $DISPLAY_ID"
    else
        echo "$(date): ERROR: Chromium process $CHROMIUM_PID exited immediately on $DISPLAY_ID"
        echo "$(date): Chromium log output:"
        cat "/tmp/piosk-$DISPLAY_ID.log" | sed "s/^/$(date): /"
    fi
    
    PORT=$((PORT + 1))
done

echo "$(date): Multi-screen mode startup completed"