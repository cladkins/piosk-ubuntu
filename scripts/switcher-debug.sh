#!/bin/bash

# PiOSK Switcher using Chromium Remote Debugging API
# This script uses the Chrome DevTools Protocol to control tab switching

# Get the user ID dynamically
PI_SUID=$(id -u)
export XDG_RUNTIME_DIR=/run/user/$PI_SUID

# Set display environment
export DISPLAY=:0

# Wait for Chromium to start
sleep 20

# Read configuration from config.json
CONFIG_FILE="/opt/piosk/config.json"

# Default values
SWITCHER_ENABLED=true
SWITCHER_INTERVAL=10
SWITCHER_REFRESH_CYCLE=10

# Read configuration if file exists
if [ -f "$CONFIG_FILE" ]; then
    # Read switcher configuration
    SWITCHER_ENABLED=$(jq -r '.switcher.enabled // true' "$CONFIG_FILE")
    SWITCHER_INTERVAL=$(jq -r '.switcher.interval // 10' "$CONFIG_FILE")
    SWITCHER_REFRESH_CYCLE=$(jq -r '.switcher.refresh_cycle // 10' "$CONFIG_FILE")
fi

# Check if switcher is enabled
if [ "$SWITCHER_ENABLED" != "true" ]; then
    echo "Switcher is disabled in configuration"
    exit 0
fi

echo "Starting PiOSK switcher with interval: ${SWITCHER_INTERVAL}s, refresh cycle: ${SWITCHER_REFRESH_CYCLE}"
echo "Using Chromium remote debugging API"

# count the number of URLs, that are configured to cycle through
URLS=$(jq -r '.urls | length' "$CONFIG_FILE")

if [ "$URLS" -eq 0 ]; then
    echo "No URLs configured, exiting switcher"
    exit 0
fi

echo "Found $URLS URLs to cycle through"

# Function to get list of tabs from Chromium
get_tabs() {
    curl -s http://localhost:9222/json/list | jq -r '.[] | select(.type == "page") | .id'
}

# Function to show all tabs for debugging
show_all_tabs() {
    echo "=== All Available Tabs ==="
    curl -s http://localhost:9222/json/list | jq -r '.[] | select(.type == "page") | "ID: \(.id) | URL: \(.url)"'
    echo "=== Current Active Tab ==="
    curl -s http://localhost:9222/json/active | jq -r '"ID: \(.id) | URL: \(.url)"'
    echo "========================"
}

# Function to activate a tab
activate_tab() {
    local tab_id="$1"
    curl -s -X POST "http://localhost:9222/json/activate/$tab_id" >/dev/null
}

# Function to reload a tab
reload_tab() {
    local tab_id="$1"
    curl -s -X POST "http://localhost:9222/json/protocol/Runtime/reload" \
        -H "Content-Type: application/json" \
        -d "{\"id\": 1, \"method\": \"Page.reload\", \"params\": {}}" \
        --data-urlencode "tabId=$tab_id" >/dev/null
}

# Function to get current tab index
get_current_tab_index() {
    local tabs=($(get_tabs))
    local current_tab_id=$(curl -s http://localhost:9222/json/active | jq -r '.id')
    
    for i in "${!tabs[@]}"; do
        if [[ "${tabs[$i]}" == "$current_tab_id" ]]; then
            echo $i
            return
        fi
    done
    echo 0
}

# Function to switch to next tab
switch_to_next_tab() {
    local tabs=($(get_tabs))
    local current_index=$(get_current_tab_index)
    local next_index=$(( (current_index + 1) % ${#tabs[@]} ))
    
    echo "Switching from tab $current_index to tab $next_index (total tabs: ${#tabs[@]})"
    echo "Current tab ID: $(curl -s http://localhost:9222/json/active | jq -r '.id')"
    echo "Next tab ID: ${tabs[$next_index]}"
    
    activate_tab "${tabs[$next_index]}"
    
    # Verify the switch worked
    sleep 1
    local new_current_id=$(curl -s http://localhost:9222/json/active | jq -r '.id')
    if [[ "$new_current_id" == "${tabs[$next_index]}" ]]; then
        echo "Tab switch successful"
        return 0
    else
        echo "Tab switch failed - expected ${tabs[$next_index]}, got $new_current_id"
        return 1
    fi
}

# Function to refresh current tab
refresh_current_tab() {
    local current_tab_id=$(curl -s http://localhost:9222/json/active | jq -r '.id')
    echo "Refreshing current tab"
    reload_tab "$current_tab_id"
}

# Wait for Chromium to be ready
echo "Waiting for Chromium remote debugging to be available..."
for i in {1..30}; do
    if curl -s http://localhost:9222/json/list >/dev/null 2>&1; then
        echo "Chromium remote debugging is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "ERROR: Chromium remote debugging not available after 30 seconds"
        exit 1
    fi
    sleep 1
done

# switch tabs each interval, refresh tabs each refresh_cycle & then reset
for ((TURN=1; TURN<=$((SWITCHER_REFRESH_CYCLE*URLS)); TURN++)) do
  if [ $TURN -le $((SWITCHER_REFRESH_CYCLE*URLS)) ]; then
    echo "Switching to next tab (turn $TURN)"
    
    # Show debug info every few turns
    if [ $((TURN % 5)) -eq 1 ]; then
        show_all_tabs
    fi
    
    # Switch to next tab
    if ! switch_to_next_tab; then
        echo "ERROR: Failed to switch tab, exiting"
        exit 1
    fi
    
    if [ $TURN -gt $(((SWITCHER_REFRESH_CYCLE-1)*URLS)) ]; then
      echo "Refreshing current tab"
      
      # Refresh current tab
      if ! refresh_current_tab; then
          echo "ERROR: Failed to refresh tab"
      fi
      
      if [ $TURN -eq $((SWITCHER_REFRESH_CYCLE*URLS)) ]; then
        (( TURN=0 ))
        echo "Completed refresh cycle, starting over"
      fi
    fi
  fi
  sleep $SWITCHER_INTERVAL
done 