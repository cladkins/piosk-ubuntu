#!/bin/bash
# Display detection for multi-screen support - works over SSH

# Get the actual user who should own the X session
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER="$USER"
fi

# Function to try xrandr with proper environment
try_xrandr() {
    local user="$1"
    local display="$2"
    
    # Try to set up proper X11 environment
    if [ -f "/home/$user/.Xauthority" ]; then
        sudo -u "$user" DISPLAY="$display" XAUTHORITY="/home/$user/.Xauthority" xrandr --listmonitors 2>/dev/null | grep "^ " | awk '{print $4}' | grep -v "^$"
    else
        sudo -u "$user" DISPLAY="$display" xrandr --listmonitors 2>/dev/null | grep "^ " | awk '{print $4}' | grep -v "^$"
    fi
}

# Try different display detection methods
DISPLAYS=""

# Method 1: Try common display identifiers
for DISPLAY_ID in ":0" ":1" ":10" ":11"; do
    RESULT=$(try_xrandr "$REAL_USER" "$DISPLAY_ID")
    if [ -n "$RESULT" ]; then
        DISPLAYS="$DISPLAYS $RESULT"
        break
    fi
done

# Method 2: Check for active X sessions
if [ -z "$DISPLAYS" ]; then
    # Look for active X sessions
    ACTIVE_DISPLAYS=$(ps aux | grep -E "Xorg|X.*:[0-9]+" | grep -v grep | sed -n 's/.*:\([0-9]\+\).*/:\1/p' | sort -u)
    for DISPLAY_ID in $ACTIVE_DISPLAYS; do
        RESULT=$(try_xrandr "$REAL_USER" "$DISPLAY_ID")
        if [ -n "$RESULT" ]; then
            DISPLAYS="$DISPLAYS $RESULT"
        fi
    done
fi

# Method 3: Check /tmp/.X11-unix/ for active displays
if [ -z "$DISPLAYS" ]; then
    for socket in /tmp/.X11-unix/X*; do
        if [ -S "$socket" ]; then
            DISPLAY_NUM=$(basename "$socket" | sed 's/X//')
            DISPLAY_ID=":$DISPLAY_NUM"
            RESULT=$(try_xrandr "$REAL_USER" "$DISPLAY_ID")
            if [ -n "$RESULT" ]; then
                DISPLAYS="$DISPLAYS $RESULT"
            fi
        fi
    done
fi

# Method 4: Try to detect hardware displays directly
if [ -z "$DISPLAYS" ]; then
    # Check for connected displays in sysfs
    if [ -d "/sys/class/drm" ]; then
        CONNECTED_COUNT=$(find /sys/class/drm -name "card*-*" -exec cat {}/status \; 2>/dev/null | grep -c "connected")
        if [ "$CONNECTED_COUNT" -gt 1 ]; then
            # Multiple displays detected, create virtual display IDs
            for i in $(seq 0 $((CONNECTED_COUNT - 1))); do
                DISPLAYS="$DISPLAYS :$i"
            done
        fi
    fi
fi

# Fallback: Use default display
if [ -z "$DISPLAYS" ]; then
    DISPLAYS=":0"
fi

# Clean up and return
echo "$DISPLAYS" | tr -s ' ' | sed 's/^ *//;s/ *$//'