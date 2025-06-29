#!/bin/bash

# PiOSK Ubuntu - Fix Switcher Autostart
# This script fixes the switcher autostart file for existing installations

set -e

echo "=== PiOSK Ubuntu - Fix Switcher Autostart ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Get the current user (who ran sudo)
ACTUAL_USER=${SUDO_USER:-$USER}

echo "Fixing switcher autostart for user: $ACTUAL_USER"

# Create autostart directory if it doesn't exist
mkdir -p /home/$ACTUAL_USER/.config/autostart

# Create the switcher autostart file
echo "Creating switcher autostart file..."
cat > /home/$ACTUAL_USER/.config/autostart/piosk-switcher-enable.desktop << EOF
[Desktop Entry]
Type=Application
Name=PiOSK Switcher Enable
Exec=/opt/piosk/scripts/enable-switcher.sh
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

# Set proper ownership and permissions
chown $ACTUAL_USER:$ACTUAL_USER /home/$ACTUAL_USER/.config/autostart/piosk-switcher-enable.desktop
chmod +x /home/$ACTUAL_USER/.config/autostart/piosk-switcher-enable.desktop

echo "Switcher autostart file created successfully!"
echo "File: /home/$ACTUAL_USER/.config/autostart/piosk-switcher-enable.desktop"

# Test if the file exists and is executable
if [ -f "/home/$ACTUAL_USER/.config/autostart/piosk-switcher-enable.desktop" ] && [ -x "/home/$ACTUAL_USER/.config/autostart/piosk-switcher-enable.desktop" ]; then
    echo "✓ Autostart file is properly configured"
else
    echo "✗ Error: Autostart file is not properly configured"
    exit 1
fi

echo ""
echo "=== Fix Complete ==="
echo "The switcher enable/disable functionality should now work correctly."
echo "Try toggling the switcher in the dashboard and rebooting to test." 