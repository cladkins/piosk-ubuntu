#!/bin/bash

# PiOSK Power Settings Test Script
# This script checks if power management settings have been applied correctly

echo "=== PiOSK Power Settings Test ==="

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "This script should not be run as root. Please run as a regular user."
    exit 1
fi

# Check if we're in a graphical session
if [ -z "$DISPLAY" ]; then
    echo "No display detected. Please run this script from a graphical session."
    exit 1
fi

echo "Testing power management settings for user: $USER"
echo ""

# Function to test gsettings
test_gsetting() {
    local schema="$1"
    local key="$2"
    local expected="$3"
    local description="$4"
    
    if command -v gsettings >/dev/null 2>&1; then
        local value=$(gsettings get "$schema" "$key" 2>/dev/null)
        if [ "$value" = "$expected" ]; then
            echo "✓ $description: $value"
        else
            echo "✗ $description: $value (expected: $expected)"
        fi
    else
        echo "? $description: gsettings not available"
    fi
}

# Function to test dconf
test_dconf() {
    local key="$1"
    local expected="$2"
    local description="$3"
    
    if command -v dconf >/dev/null 2>&1; then
        local value=$(dconf read "$key" 2>/dev/null)
        if [ "$value" = "$expected" ]; then
            echo "✓ $description: $value"
        else
            echo "✗ $description: $value (expected: $expected)"
        fi
    else
        echo "? $description: dconf not available"
    fi
}

# Test GNOME/Unity settings
echo "=== GNOME/Unity Power Settings ==="
test_gsetting "org.gnome.desktop.screensaver" "idle-activation-enabled" "false" "Screen saver idle activation"
test_gsetting "org.gnome.desktop.screensaver" "lock-enabled" "false" "Screen saver lock"
test_gsetting "org.gnome.settings-daemon.plugins.power" "sleep-display-ac" "0" "AC display sleep"
test_gsetting "org.gnome.settings-daemon.plugins.power" "sleep-display-battery" "0" "Battery display sleep"
test_gsetting "org.gnome.desktop.session" "idle-delay" "uint32 0" "Session idle delay"

echo ""

# Test KDE Plasma settings
echo "=== KDE Plasma Power Settings ==="
test_dconf "/org/kde/powerdevil/profiles/AC/DPMSControl" "0" "AC DPMS control"
test_dconf "/org/kde/powerdevil/profiles/Battery/DPMSControl" "0" "Battery DPMS control"
test_dconf "/org/kde/powerdevil/profiles/AC/autoSuspend" "0" "AC auto suspend"
test_dconf "/org/kde/powerdevil/profiles/Battery/autoSuspend" "0" "Battery auto suspend"

echo ""

# Test XFCE settings
echo "=== XFCE Power Settings ==="
test_dconf "/org/xfce/power-manager/inactivity-on-ac" "0" "AC inactivity"
test_dconf "/org/xfce/power-manager/inactivity-on-battery" "0" "Battery inactivity"
test_dconf "/org/xfce/power-manager/blank-on-ac" "0" "AC screen blank"
test_dconf "/org/xfce/power-manager/blank-on-battery" "0" "Battery screen blank"

echo ""

# Test X11 settings
echo "=== X11 Screen Saver Settings ==="
if command -v xset >/dev/null 2>&1; then
    local dpms_status=$(xset q | grep "DPMS is" | awk '{print $3}')
    if [ "$dpms_status" = "Disabled" ]; then
        echo "✓ X11 DPMS: Disabled"
    else
        echo "✗ X11 DPMS: $dpms_status (expected: Disabled)"
    fi
else
    echo "? X11 DPMS: xset not available"
fi

echo ""

# Test systemd user service
echo "=== Systemd User Service ==="
if systemctl --user is-enabled piosk-power-management.service >/dev/null 2>&1; then
    echo "✓ Power management service: Enabled"
else
    echo "✗ Power management service: Not enabled"
fi

if systemctl --user is-active piosk-power-management.service >/dev/null 2>&1; then
    echo "✓ Power management service: Active"
else
    echo "✗ Power management service: Not active"
fi

echo ""
echo "=== Test Complete ==="
echo ""
echo "If you see any ✗ marks, the power settings may not be applied correctly."
echo "Run the following to apply settings:"
echo "  /opt/piosk/scripts/apply-power-settings.sh" 