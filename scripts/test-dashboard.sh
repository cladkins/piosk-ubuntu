#!/bin/bash

# PiOSK Dashboard Test
# Test the dashboard endpoints to verify they're working correctly

set -e

echo "=== PiOSK Dashboard Test ==="
echo ""

# Check if dashboard is running
echo "1. Checking if dashboard is running..."
if curl -s http://localhost:3000 > /dev/null; then
    echo "✓ Dashboard is running on port 3000"
else
    echo "✗ Dashboard is not running on port 3000"
    echo "Please start the dashboard: node index.js"
    exit 1
fi

echo ""
echo "2. Testing config endpoint..."
CONFIG_RESPONSE=$(curl -s http://localhost:3000/config)
if [ $? -eq 0 ]; then
    echo "✓ Config endpoint working"
    echo "Config content:"
    echo "$CONFIG_RESPONSE" | jq . 2>/dev/null || echo "$CONFIG_RESPONSE"
else
    echo "✗ Config endpoint failed"
fi

echo ""
echo "3. Testing switcher status endpoint..."
STATUS_RESPONSE=$(curl -s http://localhost:3000/switcher/status)
if [ $? -eq 0 ]; then
    echo "✓ Switcher status endpoint working"
    echo "Status response:"
    echo "$STATUS_RESPONSE" | jq . 2>/dev/null || echo "$STATUS_RESPONSE"
else
    echo "✗ Switcher status endpoint failed"
fi

echo ""
echo "4. Testing switcher start endpoint..."
START_RESPONSE=$(curl -s -X POST http://localhost:3000/switcher/start)
if [ $? -eq 0 ]; then
    echo "✓ Switcher start endpoint working"
    echo "Start response:"
    echo "$START_RESPONSE" | jq . 2>/dev/null || echo "$START_RESPONSE"
else
    echo "✗ Switcher start endpoint failed"
fi

echo ""
echo "5. Testing switcher stop endpoint..."
STOP_RESPONSE=$(curl -s -X POST http://localhost:3000/switcher/stop)
if [ $? -eq 0 ]; then
    echo "✓ Switcher stop endpoint working"
    echo "Stop response:"
    echo "$STOP_RESPONSE" | jq . 2>/dev/null || echo "$STOP_RESPONSE"
else
    echo "✗ Switcher stop endpoint failed"
fi

echo ""
echo "6. Checking actual systemctl status..."
USER=$(whoami)
echo "Current user: $USER"
echo "Systemctl --user status:"
systemctl --user is-active piosk-switcher 2>/dev/null || echo "Service not active"

echo ""
echo "=== Test Complete ==="
echo ""
echo "If all endpoints are working, the dashboard should display correctly."
echo "Check the dashboard at: http://localhost:3000/switcher.html" 