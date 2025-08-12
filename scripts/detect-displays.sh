#!/bin/bash
# Simple display detection for multi-screen support

# Get the actual user who should own the X session
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER="$USER"
fi

# Ensure DISPLAY is set
export DISPLAY=${DISPLAY:-:0}

# Try to get displays as the actual user to avoid X11 auth issues
if command -v xrandr >/dev/null 2>&1; then
    # Try as the real user first
    DISPLAYS=$(sudo -u "$REAL_USER" DISPLAY="$DISPLAY" xrandr --listmonitors 2>/dev/null | grep "^ " | awk '{print $4}' | grep -v "^$")
    
    # If that fails, try alternative methods
    if [ -z "$DISPLAYS" ]; then
        DISPLAYS=$(sudo -u "$REAL_USER" DISPLAY="$DISPLAY" xrandr 2>/dev/null | grep " connected" | awk '{print $1}')
    fi
    
    # If still no displays, try without sudo
    if [ -z "$DISPLAYS" ]; then
        DISPLAYS=$(DISPLAY="$DISPLAY" xrandr --listmonitors 2>/dev/null | grep "^ " | awk '{print $4}' | grep -v "^$")
    fi
fi

# If xrandr fails completely, use default
if [ -z "$DISPLAYS" ]; then
    DISPLAYS=":0"
fi

# Return clean display list (one per line, then convert to space-separated)
echo "$DISPLAYS" | tr '\n' ' ' | sed 's/ *$//'