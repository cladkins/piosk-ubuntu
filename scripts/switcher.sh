#!/bin/bash

# PiOSK Tab Switcher - Simple and Reliable
# Uses basic keyboard simulation to cycle through tabs

set -e

# Configuration
CONFIG_FILE="/opt/piosk/config.json"
SWITCHER_INTERVAL=10
SWITCHER_REFRESH_CYCLE=10

# Read configuration if file exists
if [ -f "$CONFIG_FILE" ]; then
    SWITCHER_ENABLED=$(jq -r '.switcher.enabled // true' "$CONFIG_FILE")
    SWITCHER_INTERVAL=$(jq -r '.switcher.interval // 10' "$CONFIG_FILE")
    SWITCHER_REFRESH_CYCLE=$(jq -r '.switcher.refresh_cycle // 10' "$CONFIG_FILE")
fi

# Check if switcher is enabled
if [ "$SWITCHER_ENABLED" != "true" ]; then
    echo "Switcher is disabled in configuration"
    exit 0
fi

echo "Starting PiOSK switcher - interval: ${SWITCHER_INTERVAL}s, refresh cycle: ${SWITCHER_REFRESH_CYCLE}"

# Wait for Chromium to start
echo "Waiting for Chromium to start..."
sleep 15

# Count URLs to cycle through
URLS=$(jq -r '.urls | length' "$CONFIG_FILE")
if [ "$URLS" -eq 0 ]; then
    echo "No URLs configured, exiting switcher"
    exit 0
fi

echo "Found $URLS URLs to cycle through"

# Simple function to send Ctrl+Tab
send_ctrl_tab() {
    # Try xdotool first (most reliable)
    if command -v xdotool >/dev/null 2>&1; then
        xdotool key ctrl+Tab 2>/dev/null && return 0
    fi
    
    # Fallback to wtype
    if command -v wtype >/dev/null 2>&1; then
        wtype -M ctrl Tab 2>/dev/null && return 0
    fi
    
    # Last resort: xte
    if command -v xte >/dev/null 2>&1; then
        xte "keydown Control_L" "key Tab" "keyup Control_L" 2>/dev/null && return 0
    fi
    
    echo "ERROR: No keyboard simulation tool available"
    return 1
}

# Simple function to send Ctrl+R (refresh)
send_ctrl_r() {
    if command -v xdotool >/dev/null 2>&1; then
        xdotool key ctrl+r 2>/dev/null && return 0
    fi
    
    if command -v wtype >/dev/null 2>&1; then
        wtype -M ctrl r 2>/dev/null && return 0
    fi
    
    if command -v xte >/dev/null 2>&1; then
        xte "keydown Control_L" "key r" "keyup Control_L" 2>/dev/null && return 0
    fi
    
    return 1
}

# Main loop - cycle through tabs
turn=1
while true; do
    echo "Turn $turn: Switching to next tab"
    
    if ! send_ctrl_tab; then
        echo "ERROR: Failed to send Ctrl+Tab"
        sleep 5
        continue
    fi
    
    # Refresh on refresh cycle
    if [ $turn -ge $(((SWITCHER_REFRESH_CYCLE-1)*URLS)) ]; then
        echo "Refreshing current tab"
        if ! send_ctrl_r; then
            echo "WARNING: Failed to refresh tab"
        fi
        
        if [ $turn -eq $((SWITCHER_REFRESH_CYCLE*URLS)) ]; then
            turn=0
            echo "Completed refresh cycle, starting over"
        fi
    fi
    
    turn=$((turn + 1))
    sleep $SWITCHER_INTERVAL
done 