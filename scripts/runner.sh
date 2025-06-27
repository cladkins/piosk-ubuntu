#!/bin/bash

# Simple runner that uses the working command
echo "Starting PiOSK kiosk mode..."

# Get URLs from config file
URLS=$(jq -r '.urls | map(.url) | join(" ")' /opt/piosk/config.json)

# Use snap Chromium with the working command format
exec snap run chromium --kiosk $URLS 