#!/bin/bash

# Get the user ID dynamically
PI_SUID=$(id -u)
export XDG_RUNTIME_DIR=/run/user/$PI_SUID

# Wait for Chromium to start
sleep 20

# THIS IS NOT THE BEST WAY TO SWITCH & REFRESH TABS BUT IT WORKS
# should parameterize cycle count & sleep delay with config.json

# count the number of URLs, that are configured to cycle through
URLS=$(jq -r '.urls | length' /opt/piosk/config.json)

# switch tabs each 10s, refresh tabs each 10th cycle & then reset
for ((TURN=1; TURN<=$((10*URLS)); TURN++)) do
  if [ $TURN -le $((10*URLS)) ]; then
    # Try wtype first, fallback to xdotool if wtype fails
    if command -v wtype >/dev/null 2>&1; then
      wtype -M ctrl -P Tab
    elif command -v xdotool >/dev/null 2>&1; then
      xdotool key ctrl+Tab
    else
      echo "No keyboard simulation tool available"
      exit 1
    fi
    
    if [ $TURN -gt $((9*URLS)) ]; then
      if command -v wtype >/dev/null 2>&1; then
        wtype -M ctrl r
      elif command -v xdotool >/dev/null 2>&1; then
        xdotool key ctrl+r
      fi
      
      if [ $TURN -eq $((10*URLS)) ]; then
        (( TURN=0 ))
      fi
    fi
  fi
  sleep 10
done 