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

# Debug: Check display and window status
echo "Checking display and window status..."
if command -v xdotool >/dev/null 2>&1; then
    echo "Available windows:"
    xdotool search --name "Chromium" 2>/dev/null || echo "No Chromium windows found"
    echo "All windows:"
    xdotool search --name "" 2>/dev/null | head -5 || echo "No windows found"
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
            # Focus Chromium window first
            xdotool search --name "Chromium" windowactivate 2>/dev/null || {
                echo "Failed to focus Chromium window"
                return 1
            }
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