#!/bin/bash

# PiOSK Tab Switcher using Chromium Remote Debugging API
# This script cycles through tabs in Chromium using the remote debugging API

# Load configuration
CONFIG_FILE="/opt/piosk/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found at $CONFIG_FILE"
    exit 1
fi

# Read configuration
SWITCHER_INTERVAL=$(jq -r '.switcher.interval // 10' "$CONFIG_FILE")
SWITCHER_REFRESH_CYCLE=$(jq -r '.switcher.refresh_cycle // 10' "$CONFIG_FILE")
URLS=$(jq -r '.urls | length' "$CONFIG_FILE")

echo "Starting PiOSK switcher with interval: ${SWITCHER_INTERVAL}s, refresh cycle: $SWITCHER_REFRESH_CYCLE"
echo "Using Chromium remote debugging API"
echo "Found $URLS URLs to cycle through"

# Function to get list of tabs from Chromium
get_tabs() {
    curl -s http://localhost:9222/json/list | jq -r '.[] | select(.type == "page") | .id'
}

# Function to show all tabs for debugging
show_all_tabs() {
    echo "=== All Available Tabs ==="
    curl -s http://localhost:9222/json/list | jq -r '.[] | select(.type == "page") | "ID: \(.id) | URL: \(.url)"'
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

# Function to refresh current tab
refresh_current_tab() {
    local tabs=($(get_tabs))
    local current_index=$CURRENT_TAB_INDEX
    local tab_id="${tabs[$current_index]}"
    
    echo "Refreshing tab $current_index (ID: $tab_id)"
    reload_tab "$tab_id"
}

# Function to switch to next tab
switch_to_next_tab() {
    local tabs=($(get_tabs))
    local next_index=$(( (CURRENT_TAB_INDEX + 1) % ${#tabs[@]} ))
    
    echo "Switching from tab $CURRENT_TAB_INDEX to tab $next_index (total tabs: ${#tabs[@]})"
    echo "Next tab ID: ${tabs[$next_index]}"
    
    activate_tab "${tabs[$next_index]}"
    CURRENT_TAB_INDEX=$next_index
    
    echo "Tab switch successful - now on tab $CURRENT_TAB_INDEX"
    return 0
}

# Wait for Chromium remote debugging to be available
echo "Waiting for Chromium remote debugging to be available..."
while ! curl -s http://localhost:9222/json/list >/dev/null 2>&1; do
    sleep 1
done
echo "Chromium remote debugging is ready"

# Initialize current tab index
CURRENT_TAB_INDEX=0

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