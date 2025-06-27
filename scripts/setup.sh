#!/bin/bash

# Exit on any error
set -e

echo "=== PiOSK Ubuntu Setup ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Get the current user (who ran sudo)
ACTUAL_USER=${SUDO_USER:-$USER}

echo "Setting up PiOSK for user: $ACTUAL_USER"

# Create installation directory
echo "Creating installation directory..."
mkdir -p /opt/piosk

# Download files from GitHub
echo "Downloading files from GitHub..."
cd /tmp
git clone https://github.com/cladkins/piosk-ubuntu.git piosk-temp
cp -r piosk-temp/* /opt/piosk/
cp -r piosk-temp/.* /opt/piosk/ 2>/dev/null || true
rm -rf piosk-temp

# Make scripts executable
echo "Making scripts executable..."
chmod +x /opt/piosk/scripts/*.sh

# Fix ownership - make everything owned by the actual user
echo "Fixing ownership to user: $ACTUAL_USER"
chown -R $ACTUAL_USER:$ACTUAL_USER /opt/piosk

# Set proper permissions
echo "Setting proper permissions..."
chmod 755 /opt/piosk
chmod 755 /opt/piosk/scripts
chmod 644 /opt/piosk/config.json
chmod 644 /opt/piosk/web/*

# Create autostart entry for better X11 authorization
echo "Creating autostart entry..."
mkdir -p /home/$ACTUAL_USER/.config/autostart
cat > /home/$ACTUAL_USER/.config/autostart/piosk-kiosk.desktop << EOF
[Desktop Entry]
Type=Application
Name=PiOSK Kiosk
Comment=PiOSK Kiosk Mode
Exec=/opt/piosk/scripts/runner.sh
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

chown $ACTUAL_USER:$ACTUAL_USER /home/$ACTUAL_USER/.config/autostart/piosk-kiosk.desktop
chmod +x /home/$ACTUAL_USER/.config/autostart/piosk-kiosk.desktop

# Install systemd services (as backup/alternative)
echo "Installing systemd services..."

# Copy service templates
cp /opt/piosk/services/piosk-dashboard.template /etc/systemd/system/piosk-dashboard.service
cp /opt/piosk/services/piosk-runner.template /etc/systemd/system/piosk-runner.service
cp /opt/piosk/services/piosk-switcher.template /etc/systemd/system/piosk-switcher.service

# Replace placeholders in service files
sed -i "s/USER_PLACEHOLDER/$ACTUAL_USER/g" /etc/systemd/system/piosk-dashboard.service
sed -i "s/USER_PLACEHOLDER/$ACTUAL_USER/g" /etc/systemd/system/piosk-runner.service
sed -i "s/USER_PLACEHOLDER/$ACTUAL_USER/g" /etc/systemd/system/piosk-switcher.service

# Reload systemd
systemctl daemon-reload

echo "=== Setup Complete ==="
echo ""
echo "PiOSK will now start automatically when you log in to the desktop."
echo ""
echo "To start PiOSK manually:"
echo "  /opt/piosk/scripts/runner.sh"
echo ""
echo "To disable autostart:"
echo "  rm ~/.config/autostart/piosk-kiosk.desktop"
echo ""
echo "To view logs (if using systemd service):"
echo "  sudo journalctl -u piosk-runner -f"
echo ""
echo "To switch to dashboard mode:"
echo "  sudo systemctl start piosk-dashboard"
echo ""
echo "To switch back to kiosk mode:"
echo "  sudo systemctl start piosk-runner" 