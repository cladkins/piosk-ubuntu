#!/bin/bash
# Simple display detection for multi-screen support

# Ensure DISPLAY is set
export DISPLAY=${DISPLAY:-:0}

# Get connected displays
DISPLAYS=$(xrandr --listmonitors 2>/dev/null | grep "^ " | awk '{print $4}' | grep -v "^$" || echo ":0")

# If xrandr fails, use default
if [ -z "$DISPLAYS" ]; then
    DISPLAYS=":0"
fi

# Return clean display list
echo "$DISPLAYS"