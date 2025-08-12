#!/bin/bash

# Smart runner - starts the last active mode or defaults to single-screen

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check for last mode state file
LAST_MODE_FILE="$PROJECT_ROOT/last-mode.txt"

if [ -f "$LAST_MODE_FILE" ]; then
    LAST_MODE=$(cat "$LAST_MODE_FILE")
    echo "Last mode was: $LAST_MODE"
else
    LAST_MODE="single-screen"
    echo "No last mode found, defaulting to: $LAST_MODE"
fi

case "$LAST_MODE" in
    "multi-screen")
        echo "Starting multi-screen mode..."
        exec "$SCRIPT_DIR/runner-multiscreen.sh"
        ;;
    *)
        echo "Starting single-screen mode..."
        exec "$SCRIPT_DIR/runner.sh"
        ;;
esac