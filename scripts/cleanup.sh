#!/bin/bash

# Exit on any error
set -e

echo "=== PiOSK Ubuntu Cleanup ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Get the current user (who ran sudo)
ACTUAL_USER=${SUDO_USER:-$USER}

echo "Cleaning up PiOSK for user: $ACTUAL_USER"

# Stop and disable services
echo "Stopping and disabling services..."
systemctl stop piosk-dashboard 2>/dev/null || true
systemctl stop piosk-runner 2>/dev/null || true
systemctl stop piosk-switcher 2>/dev/null || true
systemctl disable piosk-dashboard 2>/dev/null || true
systemctl disable piosk-runner 2>/dev/null || true
systemctl disable piosk-switcher 2>/dev/null || true

# Remove service files
echo "Removing service files..."
rm -f /etc/systemd/system/piosk-dashboard.service
rm -f /etc/systemd/system/piosk-runner.service
rm -f /etc/systemd/system/piosk-switcher.service

# Remove autostart entry
echo "Removing autostart entry..."
rm -f /home/$ACTUAL_USER/.config/autostart/piosk-kiosk.desktop
rm -f /home/$ACTUAL_USER/.config/autostart/disable-screenlock.desktop

# Remove nginx configuration
echo "Removing nginx configuration..."
rm -f /etc/nginx/sites-enabled/piosk
rm -f /etc/nginx/sites-available/piosk

# Restore default nginx site if it doesn't exist
if [ ! -f /etc/nginx/sites-enabled/default ] && [ -f /etc/nginx/sites-available/default ]; then
    echo "Restoring default nginx site..."
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
fi

# Restart nginx if it's running
if systemctl is-active --quiet nginx; then
    echo "Restarting nginx..."
    systemctl restart nginx
fi

# Remove power management settings
echo "Removing power management settings..."
rm -f /etc/systemd/logind.conf.d/99-piosk.conf

# Re-enable system sleep/hibernate
echo "Re-enabling system sleep and hibernate..."
systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null || true

# Restart systemd-logind to apply changes
systemctl restart systemd-logind 2>/dev/null || true

# Remove installation directory
echo "Removing installation directory..."
rm -rf /opt/piosk

# Reload systemd
echo "Reloading systemd..."
systemctl daemon-reload

echo "=== Cleanup Complete ==="
echo ""
echo "PiOSK has been removed from your system."
echo ""
echo "Note: Autologin configuration has been left in place."
echo "If you want to remove autologin, you can:"
echo "  - Edit /etc/gdm3/custom.conf (for GDM3)"
echo "  - Edit /etc/lightdm/lightdm.conf (for LightDM)"
echo "  - Edit /etc/sddm.conf.d/autologin.conf (for SDDM)"
echo ""
echo "If you want to remove nginx completely:"
echo "  sudo apt remove nginx" 