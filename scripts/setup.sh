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

# Detect display manager
echo "Detecting display manager..."
if systemctl is-active --quiet gdm3; then
    DISPLAY_MANAGER="gdm3"
elif systemctl is-active --quiet lightdm; then
    DISPLAY_MANAGER="lightdm"
elif systemctl is-active --quiet sddm; then
    DISPLAY_MANAGER="sddm"
else
    DISPLAY_MANAGER="unknown"
fi
echo "Display manager: $DISPLAY_MANAGER"

# Configure autologin
echo "Configuring autologin..."
case $DISPLAY_MANAGER in
    "gdm3")
        echo "Configuring GDM3 autologin..."
        mkdir -p /etc/gdm3
        cat > /etc/gdm3/custom.conf << EOF
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=$ACTUAL_USER
EOF
        ;;
    "lightdm")
        echo "Configuring LightDM autologin..."
        mkdir -p /etc/lightdm
        cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=$ACTUAL_USER
autologin-user-timeout=0
EOF
        ;;
    "sddm")
        echo "Configuring SDDM autologin..."
        mkdir -p /etc/sddm.conf.d
        cat > /etc/sddm.conf.d/autologin.conf << EOF
[Autologin]
User=$ACTUAL_USER
Session=ubuntu.desktop
EOF
        ;;
    *)
        echo "Unknown display manager. Please configure autologin manually."
        ;;
esac

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

# Handle config.json - create from sample if it doesn't exist
if [ ! -f /opt/piosk/config.json ]; then
    if [ -f /opt/piosk/config.json.sample ]; then
        cp /opt/piosk/config.json.sample /opt/piosk/config.json
        echo "Created config.json from sample"
    fi
fi

# Set permissions for config and web files
if [ -f /opt/piosk/config.json ]; then
    chmod 644 /opt/piosk/config.json
fi

if [ -d /opt/piosk/web ]; then
    chmod 644 /opt/piosk/web/*
fi

# Install npm dependencies
echo "Installing npm dependencies..."
cd /opt/piosk

# Ensure we have the right ownership for npm install
chown -R $ACTUAL_USER:$ACTUAL_USER /opt/piosk

# Run npm install as the user
echo "Running npm install..."
if ! sudo -u $ACTUAL_USER npm install; then
    echo "npm install failed, trying alternative approach..."
    # Alternative: install dependencies globally or with different method
    npm install --prefix /opt/piosk
    chown -R $ACTUAL_USER:$ACTUAL_USER /opt/piosk
fi

# Verify dependencies are installed
if [ ! -d "/opt/piosk/node_modules" ] || [ ! -d "/opt/piosk/node_modules/express" ]; then
    echo "Dependencies not found, installing manually..."
    cd /opt/piosk
    npm install express@^5.0.0-beta.3
    chown -R $ACTUAL_USER:$ACTUAL_USER /opt/piosk
fi

echo "npm dependencies installed successfully"

# Install and configure nginx as reverse proxy
echo "Installing and configuring nginx..."
apt update
apt install -y nginx

# Create nginx configuration for PiOSK
cat > /etc/nginx/sites-available/piosk << EOF
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Enable the site and disable default
ln -sf /etc/nginx/sites-available/piosk /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration and restart
nginx -t && systemctl restart nginx
systemctl enable nginx

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

# Configure power management settings to prevent screen saver and auto logout
echo "Configuring power management settings..."
mkdir -p /home/$ACTUAL_USER/.config/autostart

# Create a power management configuration script that runs on autostart
cat > /home/$ACTUAL_USER/.config/autostart/piosk-power-config.desktop << EOF
[Desktop Entry]
Type=Application
Name=PiOSK Power Config
Comment=Configure power management for kiosk mode
Exec=/opt/piosk/scripts/power-config.sh
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

chown $ACTUAL_USER:$ACTUAL_USER /home/$ACTUAL_USER/.config/autostart/piosk-power-config.desktop
chmod +x /home/$ACTUAL_USER/.config/autostart/piosk-power-config.desktop

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
echo "Autologin configured for user: $ACTUAL_USER"
echo "PiOSK will now start automatically when you log in to the desktop."
echo ""
echo "Dashboard is available at:"
echo "  http://$(hostname) or http://$(hostname -I | cut -d ' ' -f1)"
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