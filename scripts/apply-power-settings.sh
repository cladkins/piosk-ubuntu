#!/bin/bash

# PiOSK Power Settings Application Script
# This script can be run manually to apply power management settings immediately

echo "=== PiOSK Power Settings Application ==="

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

echo "Applying power management settings for user: $USER"

# Run the power configuration script
if [ -f "/opt/piosk/scripts/power-config.sh" ]; then
    echo "Running power configuration script..."
    /opt/piosk/scripts/power-config.sh
else
    echo "Power configuration script not found at /opt/piosk/scripts/power-config.sh"
    echo "Please ensure PiOSK is properly installed."
    exit 1
fi

echo ""
echo "=== Power Settings Applied ==="
echo "The following settings have been applied:"
echo "- Screen saver disabled"
echo "- Auto logout disabled"
echo "- Display power management disabled"
echo "- System sleep/hibernate disabled"
echo ""
echo "These settings will persist across reboots."
echo "To revert these settings, run the cleanup script:"
echo "  sudo /opt/piosk/scripts/cleanup.sh" 