#!/bin/bash

# PiOSK Dashboard Service Fix Script
# This script fixes the dashboard service configuration for existing installations

echo "=== PiOSK Dashboard Service Fix ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Get the current user (who ran sudo)
ACTUAL_USER=${SUDO_USER:-$USER}

echo "Fixing dashboard service for user: $ACTUAL_USER"

# Stop the service if it's running
echo "Stopping dashboard service..."
systemctl stop piosk-dashboard 2>/dev/null || true

# Backup the current service file
if [ -f /etc/systemd/system/piosk-dashboard.service ]; then
    echo "Backing up current service file..."
    cp /etc/systemd/system/piosk-dashboard.service /etc/systemd/system/piosk-dashboard.service.backup
fi

# Create the improved service file
echo "Creating improved service file..."
cat > /etc/systemd/system/piosk-dashboard.service << EOF
[Unit]
Description=Run PiOSK dashboard
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/npm start --prefix /opt/piosk/
User=$ACTUAL_USER
WorkingDirectory=/opt/piosk
Restart=on-failure
RestartSec=10
Environment=NODE_ENV=production
Environment=HOME=/home/$ACTUAL_USER

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
echo "Reloading systemd..."
systemctl daemon-reload

# Enable and start the service
echo "Enabling and starting dashboard service..."
systemctl enable piosk-dashboard
if systemctl start piosk-dashboard; then
    echo "✓ Dashboard service started successfully"
    echo "✓ Service status:"
    systemctl status piosk-dashboard --no-pager -l
else
    echo "✗ Failed to start dashboard service automatically"
    echo "Trying alternative configuration..."
    
    # Try the direct node approach
    cat > /etc/systemd/system/piosk-dashboard.service << EOF
[Unit]
Description=Run PiOSK dashboard (Node.js direct)
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node /opt/piosk/index.js
User=$ACTUAL_USER
WorkingDirectory=/opt/piosk
Restart=on-failure
RestartSec=10
Environment=NODE_ENV=production
Environment=HOME=/home/$ACTUAL_USER

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable piosk-dashboard
    
    if systemctl start piosk-dashboard; then
        echo "✓ Dashboard service started successfully with direct node execution"
        echo "✓ Service status:"
        systemctl status piosk-dashboard --no-pager -l
    else
        echo "✗ Failed to start dashboard service with both configurations"
        echo "Please check the logs: sudo journalctl -u piosk-dashboard -n 20"
        echo "You can run the dashboard manually: cd /opt/piosk && sudo -u $ACTUAL_USER npm start"
    fi
fi

echo ""
echo "=== Fix Complete ==="
echo ""
echo "To test the dashboard:"
echo "  curl http://localhost:3000"
echo "  curl http://localhost"
echo ""
echo "To view service logs:"
echo "  sudo journalctl -u piosk-dashboard -f" 