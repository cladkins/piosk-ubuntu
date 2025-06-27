#!/bin/bash

# Set up environment for X11
export DISPLAY=:0
export XAUTHORITY=/home/cladkins/.Xauthority
export XDG_RUNTIME_DIR=/run/user/1000
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

# Wait a bit for the session to be ready
sleep 5

# Try to fix X11 authorization
if [ -S /tmp/.X11-unix/X0 ]; then
    echo "X11 socket found, attempting to fix authorization..."
    
    # Try to copy authorization from the existing session
    if [ -f "/home/cladkins/.Xauthority" ]; then
        echo "Using existing .Xauthority file"
    else
        echo "No .Xauthority file found, trying to copy from display..."
        # Try to copy the authorization from the display
        xauth list "$DISPLAY" 2>/dev/null | while read line; do
            if [ -n "$line" ]; then
                echo "Found X11 auth: $line"
                echo "$line" | xauth add "$DISPLAY" . trusted
                break
            fi
        done
    fi
    
    # Alternative: try to connect without authorization
    echo "Attempting to allow local connections..."
    xhost +local: 2>/dev/null || echo "xhost failed, trying alternative method..."
fi

# Check which Chromium is available and use the appropriate one
# Prioritize snap Chromium as it might handle permissions better
if command -v snap >/dev/null 2>&1 && snap list | grep -q chromium; then
    echo "Using snap Chromium: snap run chromium"
    CHROMIUM_CMD="snap run chromium"
elif command -v /usr/bin/chromium-browser >/dev/null 2>&1; then
    echo "Using system Chromium: /usr/bin/chromium-browser"
    CHROMIUM_CMD="/usr/bin/chromium-browser"
else
    echo "No Chromium found!"
    exit 1
fi

# Run the main script with the correct Chromium command
CHROMIUM_CMD="$CHROMIUM_CMD" exec /opt/piosk/scripts/runner.sh 