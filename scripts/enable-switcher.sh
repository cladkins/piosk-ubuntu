#!/bin/bash

# PiOSK Ubuntu - Enable Switcher Service
# This script enables the PiOSK switcher service for the current user

set -e

echo "=== PiOSK Ubuntu - Enable Switcher Service ==="
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

echo "Enabling PiOSK switcher service..."
systemctl --user enable piosk-switcher

echo "Starting PiOSK switcher service..."
systemctl --user start piosk-switcher

echo "Checking service status..."
systemctl --user status piosk-switcher --no-pager

echo ""
echo "=== Switcher Service Enabled ==="
echo "The switcher service is now running and will start automatically on login."
echo ""
echo "To view switcher logs:"
echo "  journalctl --user -u piosk-switcher -f"
echo ""
echo "To stop the switcher service:"
echo "  systemctl --user stop piosk-switcher"
echo ""
echo "To disable the switcher service:"
echo "  systemctl --user disable piosk-switcher" 