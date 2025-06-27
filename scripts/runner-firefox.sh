#!/bin/bash

# Firefox runner that uses the working command
echo "Starting PiOSK kiosk mode with Firefox..."

# Get URLs from config file
URLS=$(jq -r '.urls | map(.url) | join(" ")' /opt/piosk/config.json)

# Use Firefox with kiosk mode
exec firefox --kiosk $URLS 