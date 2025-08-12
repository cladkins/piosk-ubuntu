#!/bin/bash
# Display detection for multi-screen support - works over SSH and Wayland

# Count actual connected hardware displays
count_connected_displays() {
    local count=0
    if [ -d "/sys/class/drm" ]; then
        # Check each card directory for connected status
        for status_file in /sys/class/drm/card*/status; do
            if [ -f "$status_file" ]; then
                if grep -q "^connected" "$status_file" 2>/dev/null; then
                    count=$((count + 1))
                fi
            fi
        done
        
        # If we found nothing, check the card1-* format you have
        if [ "$count" -eq 0 ]; then
            for status_file in /sys/class/drm/card*-*/status; do
                if [ -f "$status_file" ]; then
                    # Only count "connected" not "disconnected"
                    if grep -q "^connected" "$status_file" 2>/dev/null; then
                        count=$((count + 1))
                    fi
                fi
            done
        fi
    fi
    
    # If still zero, default to 1
    if [ "$count" -eq 0 ]; then
        count=1
    fi
    
    echo "$count"
}

# Get actual connected display count
CONNECTED_COUNT=$(count_connected_displays)

# Debug output (comment out in production)
# echo "Debug: Found $CONNECTED_COUNT connected displays" >&2

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