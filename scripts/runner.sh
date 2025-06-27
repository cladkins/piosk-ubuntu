#!/bin/bash

echo "=== PiOSK Runner Debug Info ==="
echo "Running as user: $(whoami)"
echo "Current DISPLAY: $DISPLAY"
echo "Current XAUTHORITY: $XAUTHORITY"
echo "Current XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
echo ""

# Wait for display to be ready
sleep 10

# Check if display is available - try multiple methods
DISPLAY_READY=false
for i in {1..30}; do
    if xset q >/dev/null 2>&1; then
        echo "Display is available"
        DISPLAY_READY=true
        break
    elif [ -S /tmp/.X11-unix/X0 ]; then
        echo "X11 socket found, checking user session..."
        # Check if user is logged in and has a session
        if who | grep -q "$(whoami)" && [ -n "$DISPLAY" ]; then
            echo "User session found, display should be ready"
            DISPLAY_READY=true
            break
        else
            echo "X11 socket exists but user not logged in, waiting... (attempt $i/30)"
            sleep 2
        fi
    else
        echo "Display not available, waiting... (attempt $i/30)"
        sleep 2
    fi
done

if [ "$DISPLAY_READY" = false ]; then
    echo "Display still not available after 60 seconds, trying anyway..."
    # Set DISPLAY explicitly in case it's not set
    export DISPLAY=:0
fi

# Fix X11 authorization issues
echo "=== Fixing X11 Authorization ==="
if [ ! -f "$XAUTHORITY" ]; then
    echo "Xauthority file not found, creating it..."
    touch "$XAUTHORITY"
    chmod 600 "$XAUTHORITY"
    xauth generate :0 . trusted
fi

# Allow local connections to X server
echo "Allowing local connections to X server..."
xhost +local: >/dev/null 2>&1 || echo "xhost command failed, continuing anyway..."

# Check if chromium-browser is available
if ! command -v /usr/bin/chromium-browser >/dev/null 2>&1; then
    echo "chromium-browser not found at /usr/bin/chromium-browser"
    exit 1
fi

echo "Starting Chromium with URLs: $(jq -r '.urls | map(.url) | join(" ")' /opt/piosk/config.json)"

# Launch Chromium with Ubuntu-optimized parameters
exec /usr/bin/chromium-browser \
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
  --disable-features=VizDisplayCompositor \
  --disable-dev-shm-usage \
  --no-sandbox \
  --disable-setuid-sandbox 