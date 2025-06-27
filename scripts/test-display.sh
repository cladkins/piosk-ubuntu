#!/bin/bash

echo "=== Display and Auto-login Test ==="
echo "Current user: $(whoami)"
echo "DISPLAY variable: $DISPLAY"
echo ""

echo "=== User Sessions ==="
who
echo ""

echo "=== X11 Socket ==="
ls -la /tmp/.X11-unix/ 2>/dev/null || echo "No X11 socket found"
echo ""

echo "=== Display Test ==="
if xset q >/dev/null 2>&1; then
    echo "✓ Display is responding to xset"
else
    echo "✗ Display is not responding to xset"
fi
echo ""

echo "=== Auto-login Status ==="
if systemctl is-active --quiet gdm3; then
    echo "GDM3 is active"
    echo "GDM3 config:"
    cat /etc/gdm3/custom.conf 2>/dev/null || echo "No custom GDM3 config found"
elif systemctl is-active --quiet lightdm; then
    echo "LightDM is active"
    echo "LightDM config:"
    cat /etc/lightdm/lightdm.conf 2>/dev/null || echo "No LightDM config found"
elif systemctl is-active --quiet sddm; then
    echo "SDDM is active"
    echo "SDDM config:"
    cat /etc/sddm.conf.d/autologin.conf 2>/dev/null || echo "No SDDM autologin config found"
else
    echo "No display manager found"
fi
echo ""

echo "=== Chromium Test ==="
if command -v /usr/bin/chromium-browser >/dev/null 2>&1; then
    echo "✓ chromium-browser found at /usr/bin/chromium-browser"
else
    echo "✗ chromium-browser not found"
fi 