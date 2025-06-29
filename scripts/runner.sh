#!/bin/bash

# PiOSK Ubuntu - Kiosk Mode Runner
# This script launches Chromium in kiosk mode with the configured URLs

set -e

echo "Starting PiOSK kiosk mode..."

# Set up X11 environment
export DISPLAY=:0
export XAUTHORITY=/home/$USER/.Xauthority

# Ensure we have a display
if [ -z "$DISPLAY" ]; then
    echo "Error: No display available"
    exit 1
fi

# Wait a moment for the desktop to be ready
sleep 2

# Get URLs from config file
if [ -f "/opt/piosk/config.json" ]; then
    URLS=$(jq -r '.urls | map(.url) | join(" ")' /opt/piosk/config.json)
else
    echo "Error: config.json not found"
    exit 1
fi

# Kill any existing Chromium processes
pkill chromium || true

# Wait a moment for processes to terminate
sleep 1

echo "Launching Chromium in kiosk mode with URLs: $URLS"

# Use snap Chromium with remote debugging enabled
exec snap run chromium --kiosk --remote-debugging-port=9222 --no-first-run --disable-default-apps --disable-extensions --disable-plugins --disable-sync --disable-translate --disable-web-security --allow-running-insecure-content --disable-features=VizDisplayCompositor $URLS 