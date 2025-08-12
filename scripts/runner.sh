#!/bin/bash

# Simple runner that uses the working command
echo "Starting PiOSK kiosk mode..."

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Get URLs from config file
URLS=$(jq -r '.urls | map(.url) | join(" ")' "$PROJECT_ROOT/config.json")

# Use snap Chromium with remote debugging enabled
exec snap run chromium --kiosk --remote-debugging-port=9222 $URLS 