#!/bin/bash

# Simple runner that uses the working command
echo "Starting PiOSK kiosk mode..."

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if Chromium is installed
if ! command -v snap >/dev/null 2>&1; then
    echo "Error: snap is not installed"
    exit 1
fi

if ! snap list chromium >/dev/null 2>&1; then
    echo "Error: Chromium snap is not installed. Please install with: sudo snap install chromium"
    exit 1
fi

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is not installed. Please install with: sudo apt install jq"
    exit 1
fi

# Get URLs from config file
URLS=$(jq -r '.urls | map(.url) | join(" ")' "$PROJECT_ROOT/config.json")

if [ -z "$URLS" ] || [ "$URLS" = "null" ]; then
    echo "Error: No URLs found in config.json"
    exit 1
fi

echo "Starting Chromium with URLs: $URLS"

# Use snap Chromium with remote debugging enabled
exec snap run chromium --kiosk --remote-debugging-port=9222 $URLS 