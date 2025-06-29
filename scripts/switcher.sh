#!/bin/bash

# PiOSK Tab Switcher - Simple Keyboard-Based Approach
# Based on the original PiOSK implementation which uses Ctrl+Tab to cycle through tabs

# Get the user ID dynamically
PI_SUID=$(id -u)
export XDG_RUNTIME_DIR=/run/user/$PI_SUID

# Set display environment
export DISPLAY=:0

# Wait for Chromium to start
sleep 20

# Read configuration from config.json
CONFIG_FILE="/opt/piosk/config.json"

# Default values
SWITCHER_ENABLED=true
SWITCHER_INTERVAL=10
SWITCHER_REFRESH_CYCLE=10

# Read configuration if file exists
if [ -f "$CONFIG_FILE" ]; then
    # Read switcher configuration
    SWITCHER_ENABLED=$(jq -r '.switcher.enabled // true' "$CONFIG_FILE")
    SWITCHER_INTERVAL=$(jq -r '.switcher.interval // 10' "$CONFIG_FILE")
    SWITCHER_REFRESH_CYCLE=$(jq -r '.switcher.refresh_cycle // 10' "$CONFIG_FILE")
fi

# Check if switcher is enabled
if [ "$SWITCHER_ENABLED" != "true" ]; then
    echo "Switcher is disabled in configuration"
    exit 0
fi

echo "Starting PiOSK switcher with interval: ${SWITCHER_INTERVAL}s, refresh cycle: ${SWITCHER_REFRESH_CYCLE}"
echo "Using display: $DISPLAY"
echo "Running as user: $(whoami)"
echo "User ID: $(id -u)"

# Debug: Check display and window status
echo "Checking display and window status..."
if command -v xdotool >/dev/null 2>&1; then
    echo "Available windows:"
    xdotool search --name "Chromium" 2>/dev/null || echo "No Chromium windows found"
    echo "All windows:"
    xdotool search --name "" 2>/dev/null | head -5 || echo "No windows found"
    
    # Try different window name patterns
    echo "Trying different window name patterns..."
    xdotool search --name "chrome" 2>/dev/null || echo "No 'chrome' windows found"
    xdotool search --name "browser" 2>/dev/null || echo "No 'browser' windows found"
    xdotool search --class "chromium" 2>/dev/null || echo "No 'chromium' class windows found"
    xdotool search --class "chrome" 2>/dev/null || echo "No 'chrome' class windows found"
fi

# count the number of URLs, that are configured to cycle through
URLS=$(jq -r '.urls | length' "$CONFIG_FILE")

if [ "$URLS" -eq 0 ]; then
    echo "No URLs configured, exiting switcher"
    exit 0
fi

echo "Found $URLS URLs to cycle through"

# Check for keyboard simulation tools (prioritize xdotool for XWayland)
KEYBOARD_TOOL=""
if command -v xdotool >/dev/null 2>&1; then
    echo "Using xdotool for keyboard simulation (XWayland)"
    KEYBOARD_TOOL="xdotool"
elif command -v wtype >/dev/null 2>&1; then
    echo "Using wtype for keyboard simulation (Wayland)"
    KEYBOARD_TOOL="wtype"
elif command -v xte >/dev/null 2>&1; then
    echo "Using xte for keyboard simulation"
    KEYBOARD_TOOL="xte"
else
    echo "ERROR: No keyboard simulation tool available (xdotool, wtype, or xte)"
    echo "Please install xdotool: sudo apt install xdotool"
    exit 1
fi

# Function to send keyboard events
send_key() {
    local key="$1"
    
    # First, try to focus the Chromium window
    case $KEYBOARD_TOOL in
        "xdotool")
            # Try different window name patterns
            local window_found=false
            local window_patterns=("Chromium" "chrome" "browser" "Google Chrome")
            
            for pattern in "${window_patterns[@]}"; do
                echo "Trying to focus window with pattern: $pattern"
                if xdotool search --name "$pattern" windowactivate 2>/dev/null; then
                    echo "Successfully focused window with pattern: $pattern"
                    window_found=true
                    break
                fi
            done
            
            # If no window found by name, try by class
            if [ "$window_found" = false ]; then
                echo "Trying to focus window by class..."
                if xdotool search --class "chromium" windowactivate 2>/dev/null || \
                   xdotool search --class "chrome" windowactivate 2>/dev/null; then
                    echo "Successfully focused window by class"
                    window_found=true
                fi
            fi
            
            if [ "$window_found" = false ]; then
                echo "Failed to focus any browser window"
                return 1
            fi
            
            sleep 0.5
            
            # Now send the key
            xdotool key "$key" 2>/dev/null || {
                echo "xdotool failed for key: $key"
                return 1
            }
            ;;
        "wtype")
            wtype "$key" 2>/dev/null || {
                echo "wtype failed for key: $key"
                return 1
            }
            ;;
        "xte")
            xte "key $key" 2>/dev/null || {
                echo "xte failed for key: $key"
                return 1
            }
            ;;
    esac
}

# switch tabs each interval, refresh tabs each refresh_cycle & then reset
for ((TURN=1; TURN<=$((SWITCHER_REFRESH_CYCLE*URLS)); TURN++)) do
  if [ $TURN -le $((SWITCHER_REFRESH_CYCLE*URLS)) ]; then
    echo "Switching to next tab (turn $TURN)"
    
    # Send Ctrl+Tab to cycle to next tab
    if ! send_key "ctrl+Tab"; then
        echo "ERROR: Failed to send Ctrl+Tab, exiting"
        exit 1
    fi
    
    if [ $TURN -gt $(((SWITCHER_REFRESH_CYCLE-1)*URLS)) ]; then
      echo "Refreshing current tab"
      
      # Send Ctrl+R to refresh current tab
      if ! send_key "ctrl+r"; then
          echo "ERROR: Failed to send Ctrl+R"
      fi
      
      if [ $TURN -eq $((SWITCHER_REFRESH_CYCLE*URLS)) ]; then
        (( TURN=0 ))
        echo "Completed refresh cycle, starting over"
      fi
    fi
  fi
  sleep $SWITCHER_INTERVAL
done 