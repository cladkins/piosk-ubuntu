#!/bin/bash

# PiOSK Ubuntu - Enable Switcher Service
# This script enables the PiOSK switcher service for the current user
# It checks the configuration file to determine if the switcher should be enabled

set -e

echo "=== PiOSK Ubuntu - Switcher Service Manager ==="
echo ""

# Check if we're running as a user (not root)
if [ "$EUID" -eq 0 ]; then
    echo "Error: This script should be run as a regular user, not as root"
    echo "Please run: ./scripts/enable-switcher.sh"
    exit 1
fi

# Check if user service directory exists
if [ ! -d "$HOME/.config/systemd/user" ]; then
    echo "Error: User systemd directory not found"
    echo "Please run the setup script first: sudo ./scripts/setup.sh"
    exit 1
fi

# Check if switcher service file exists
if [ ! -f "$HOME/.config/systemd/user/piosk-switcher.service" ]; then
    echo "Error: Switcher service file not found"
    echo "Please run the setup script first: sudo ./scripts/setup.sh"
    exit 1
fi

# Check configuration file to see if switcher should be enabled
CONFIG_FILE="/opt/piosk/config.json"
if [ -f "$CONFIG_FILE" ]; then
    SWITCHER_ENABLED=$(jq -r '.switcher.enabled // true' "$CONFIG_FILE")
    echo "Configuration shows switcher enabled: $SWITCHER_ENABLED"
else
    echo "Warning: config.json not found, defaulting to enabled"
    SWITCHER_ENABLED="true"
fi

if [ "$SWITCHER_ENABLED" = "true" ]; then
    echo "Enabling PiOSK switcher service..."
    systemctl --user enable piosk-switcher 2>/dev/null || echo "Service already enabled"

    echo "Starting PiOSK switcher service..."
    if systemctl --user start piosk-switcher 2>/dev/null; then
        echo "Switcher service started successfully"
    else
        echo "Warning: Could not start switcher service (may already be running)"
    fi
else
    echo "Switcher is disabled in configuration, stopping and disabling service..."
    systemctl --user stop piosk-switcher 2>/dev/null || echo "Service already stopped"
    systemctl --user disable piosk-switcher 2>/dev/null || echo "Service already disabled"
fi

echo "Checking service status..."
systemctl --user status piosk-switcher --no-pager 2>/dev/null || echo "Service status unavailable"

echo ""
echo "=== Switcher Service Setup Complete ==="
if [ "$SWITCHER_ENABLED" = "true" ]; then
    echo "The switcher service is now enabled and will start automatically on login."
else
    echo "The switcher service is now disabled and will not start automatically."
fi
echo ""
echo "To view switcher logs:"
echo "  journalctl --user -u piosk-switcher -f"
echo ""
echo "To stop the switcher service:"
echo "  systemctl --user stop piosk-switcher"
echo ""
echo "To disable the switcher service:"
echo "  systemctl --user disable piosk-switcher" 