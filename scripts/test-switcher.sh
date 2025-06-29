#!/bin/bash

# PiOSK Tab Switcher Test
# Simple test to verify keyboard simulation works

set -e

echo "=== PiOSK Tab Switcher Test ==="
echo ""

# Check if we're in a desktop environment
if [ -z "$DISPLAY" ]; then
    echo "ERROR: No DISPLAY environment variable set"
    echo "Please run this from a desktop session"
    exit 1
fi

echo "Display: $DISPLAY"
echo "User: $(whoami)"
echo ""

# Check for keyboard simulation tools
echo "Checking for keyboard simulation tools..."
if command -v xdotool >/dev/null 2>&1; then
    echo "✓ xdotool found"
    KEYBOARD_TOOL="xdotool"
elif command -v wtype >/dev/null 2>&1; then
    echo "✓ wtype found"
    KEYBOARD_TOOL="wtype"
elif command -v xte >/dev/null 2>&1; then
    echo "✓ xte found"
    KEYBOARD_TOOL="xte"
else
    echo "✗ No keyboard simulation tool found"
    echo "Please install xdotool: sudo apt install xdotool"
    exit 1
fi

# Test basic keyboard simulation
echo ""
echo "Testing keyboard simulation..."
echo "You should see a tab switch in 3 seconds..."

sleep 3

case $KEYBOARD_TOOL in
    "xdotool")
        echo "Sending Ctrl+Tab with xdotool..."
        xdotool key ctrl+Tab
        ;;
    "wtype")
        echo "Sending Ctrl+Tab with wtype..."
        wtype -M ctrl Tab
        ;;
    "xte")
        echo "Sending Ctrl+Tab with xte..."
        xte "keydown Control_L" "key Tab" "keyup Control_L"
        ;;
esac

echo ""
echo "Test completed!"
echo "If you saw a tab switch, the switcher should work."
echo ""
echo "To test the full switcher:"
echo "  ./scripts/switcher.sh" 