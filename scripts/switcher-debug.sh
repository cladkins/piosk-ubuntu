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
    local tabs=($(get_tabs))
    for i in "${!tabs[@]}"; do
        local url=$(curl -s http://localhost:9222/json/list | jq -r ".[] | select(.id == \"${tabs[$i]}\") | .url")
        echo "Tab $i: ID: ${tabs[$i]} | URL: $url"
    done
    echo "Current tab index: $CURRENT_TAB_INDEX"
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

# Function to get current tab ID
get_current_tab_id() {
    # Try to get the active tab, but if that fails, use the first tab
    local active_tab=$(curl -s http://localhost:9222/json/active 2>/dev/null | jq -r '.id // empty')
    if [ -n "$active_tab" ] && [ "$active_tab" != "null" ]; then
        echo "$active_tab"
    else
        # Fallback to first tab
        get_tabs | head -1
    fi
}

# Function to get current tab index
get_current_tab_index() {
    local current_tab_id=$(get_current_tab_id)
    local tabs=($(get_tabs))
    
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
    echo "Current tab ID: $(get_current_tab_id)"
    echo "Next tab ID: ${tabs[$next_index]}"
    
    activate_tab "${tabs[$next_index]}"
    
    # Small delay to ensure switch completes
    sleep 0.5
    
    # Verify the switch worked
    local new_current_id=$(get_current_tab_id)
    if [[ "$new_current_id" == "${tabs[$next_index]}" ]]; then
        echo "Tab switch successful - now on tab $next_index"
        return 0
    else
        echo "Tab switch verification failed - expected ${tabs[$next_index]}, got $new_current_id"
        return 1
    fi
}

# Function to refresh current tab
refresh_current_tab() {
    local current_tab_id=$(get_current_tab_id)
    echo "Refreshing current tab (ID: $current_tab_id)"
    reload_tab "$current_tab_id"
}

# Wait for Chromium remote debugging to be available
echo "Waiting for Chromium remote debugging to be available..."
while ! curl -s http://localhost:9222/json/list >/dev/null 2>&1; do
    sleep 1
done
echo "Chromium remote debugging is ready"

# switch tabs each interval, refresh tabs each refresh_cycle & then reset
for ((TURN=1; TURN<=$((SWITCHER_REFRESH_CYCLE*URLS)); TURN++)) do
  if [ $TURN -le $((SWITCHER_REFRESH_CYCLE*URLS)) ]; then
    echo "=== Turn $TURN ==="
    echo "Current tab index before switch: $(get_current_tab_index)"
    
    # Show debug info every few turns
    if [ $((TURN % 3)) -eq 1 ]; then
        show_all_tabs
    fi
    
    # Switch to next tab
    if ! switch_to_next_tab; then
        echo "ERROR: Failed to switch tab, exiting"
        exit 1
    fi
    
    echo "Current tab index after switch: $(get_current_tab_index)"
    echo "=================="
    
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