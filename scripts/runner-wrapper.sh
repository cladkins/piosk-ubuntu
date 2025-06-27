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
    
    # Create .Xauthority if it doesn't exist
    if [ ! -f "$XAUTHORITY" ]; then
        touch "$XAUTHORITY"
        chmod 600 "$XAUTHORITY"
    fi
    
    # Try to copy authorization from the display
    xauth list | grep "$DISPLAY" >/dev/null 2>&1 || {
        echo "No X11 authorization found, trying to generate..."
        xauth generate "$DISPLAY" . trusted 2>/dev/null || echo "Failed to generate X11 auth"
    }
fi

# Run the main script
exec /opt/piosk/scripts/runner.sh 