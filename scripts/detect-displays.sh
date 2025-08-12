#!/bin/bash
# Display detection for multi-screen support - works over SSH and Wayland

# Count actual connected hardware displays
count_connected_displays() {
    if [ -d "/sys/class/drm" ]; then
        find /sys/class/drm -name "status" -exec cat {} \; 2>/dev/null | grep -c "connected"
    else
        echo "1"
    fi
}

# Get actual connected display count
CONNECTED_COUNT=$(count_connected_displays)

# Debug output (comment out in production)
echo "Debug: Found $CONNECTED_COUNT connected displays" >&2

# Generate display IDs based on connected hardware
if [ "$CONNECTED_COUNT" -gt 1 ]; then
    # Multiple displays detected - create IDs for each
    DISPLAYS=""
    for i in $(seq 0 $((CONNECTED_COUNT - 1))); do
        DISPLAYS="$DISPLAYS :$i"
    done
else
    # Single display
    DISPLAYS=":0"
fi

# Clean up and return
echo "$DISPLAYS" | tr -s ' ' | sed 's/^ *//;s/ *$//'