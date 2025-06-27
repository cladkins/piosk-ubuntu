#!/bin/bash

# Wait for display to be ready
sleep 5

# Check if display is available
if ! xset q >/dev/null 2>&1; then
    echo "Display not available, waiting..."
    sleep 10
fi

# Launch Chromium with Ubuntu-optimized parameters
chromium-browser \
  $(jq -r '.urls | map(.url) | join(" ")' /opt/piosk/config.json) \
  --disable-component-update \
  --disable-composited-antialiasing \
  --disable-gpu-driver-bug-workarounds \
  --disable-infobars \
  --disable-low-res-tiling \
  --disable-pinch \
  --disable-session-crashed-bubble \
  --disable-smooth-scrolling \
  --enable-accelerated-video-decode \
  --enable-gpu-rasterization \
  --enable-low-end-device-mode \
  --enable-oop-rasterization \
  --force-device-scale-factor=1 \
  --ignore-gpu-blocklist \
  --kiosk \
  --no-first-run \
  --noerrdialogs \
  --disable-web-security \
  --disable-features=VizDisplayCompositor \
  --disable-dev-shm-usage \
  --no-sandbox \
  --disable-setuid-sandbox 