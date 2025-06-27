#!/bin/bash

# Set up environment for X11
export DISPLAY=:0
export XAUTHORITY=/home/cladkins/.Xauthority
export XDG_RUNTIME_DIR=/run/user/1000
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

# Additional environment variables for snap Chromium
export WAYLAND_DISPLAY=wayland-0
export QT_QPA_PLATFORM=xcb

# Wait a bit for the session to be ready
sleep 5

# Try to fix X11 authorization
if [ -S /tmp/.X11-unix/X0 ]; then
    echo "X11 socket found, attempting to fix authorization..."
    
    # Try to copy authorization from the current user session
    if [ -f "/home/cladkins/.Xauthority" ]; then
        echo "Using existing .Xauthority file"
        # Try to copy the current session's authorization
        CURRENT_USER=$(who | grep -E "\(:0\)" | awk '{print $1}' | head -1)
        if [ -n "$CURRENT_USER" ] && [ "$CURRENT_USER" != "cladkins" ]; then
            echo "Copying X11 auth from user: $CURRENT_USER"
            sudo -u $CURRENT_USER xauth list :0 2>/dev/null | while read line; do
                if [ -n "$line" ]; then
                    echo "Found X11 auth: $line"
                    echo "$line" | xauth add :0 . trusted
                    break
                fi
            done
        fi
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
    
    # Try multiple methods to allow connections
    echo "Attempting to allow local connections..."
    xhost +local: 2>/dev/null || echo "xhost failed, trying alternative method..."
    
    # Try to disable X11 authorization entirely
    echo "Attempting to disable X11 authorization..."
    xhost + 2>/dev/null || echo "xhost + failed"
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

# Try to run as the current logged-in user if different from cladkins
CURRENT_USER=$(who | grep -E "\(:0\)" | awk '{print $1}' | head -1)
if [ -n "$CURRENT_USER" ] && [ "$CURRENT_USER" != "cladkins" ]; then
    echo "Attempting to run as current user: $CURRENT_USER"
    # Get the user's home directory
    USER_HOME=$(eval echo ~$CURRENT_USER)
    export XAUTHORITY="$USER_HOME/.Xauthority"
    export XDG_RUNTIME_DIR="/run/user/$(id -u $CURRENT_USER)"
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $CURRENT_USER)/bus"
    
    # Run as the current user
    sudo -u $CURRENT_USER -E CHROMIUM_CMD="$CHROMIUM_CMD" exec /opt/piosk/scripts/runner.sh
else
    # Run as cladkins
    CHROMIUM_CMD="$CHROMIUM_CMD" exec /opt/piosk/scripts/runner.sh 