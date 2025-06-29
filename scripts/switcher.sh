#!/bin/bash

# Get the user ID dynamically
PI_SUID=$(id -u)
export XDG_RUNTIME_DIR=/run/user/$PI_SUID

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

# count the number of URLs, that are configured to cycle through
URLS=$(jq -r '.urls | length' "$CONFIG_FILE")

if [ "$URLS" -eq 0 ]; then
    echo "No URLs configured, exiting switcher"
    exit 0
fi

echo "Found $URLS URLs to cycle through"

# switch tabs each interval, refresh tabs each refresh_cycle & then reset
for ((TURN=1; TURN<=$((SWITCHER_REFRESH_CYCLE*URLS)); TURN++)) do
  if [ $TURN -le $((SWITCHER_REFRESH_CYCLE*URLS)) ]; then
    # Try wtype first, fallback to xdotool if wtype fails
    if command -v wtype >/dev/null 2>&1; then
      wtype -M ctrl -P Tab
    elif command -v xdotool >/dev/null 2>&1; then
      xdotool key ctrl+Tab
    else
      echo "No keyboard simulation tool available"
      exit 1
    fi
    
    if [ $TURN -gt $(((SWITCHER_REFRESH_CYCLE-1)*URLS)) ]; then
      if command -v wtype >/dev/null 2>&1; then
        wtype -M ctrl r
      elif command -v xdotool >/dev/null 2>&1; then
        xdotool key ctrl+r
      fi
      
      if [ $TURN -eq $((SWITCHER_REFRESH_CYCLE*URLS)) ]; then
        (( TURN=0 ))
      fi
    fi
  fi
  sleep $SWITCHER_INTERVAL
done 