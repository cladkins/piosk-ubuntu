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

# Function to get list of URLs from config
get_urls_from_config() {
    jq -r '.urls[]' "$CONFIG_FILE"
}

# Function to get current URL
get_current_url() {
    local tabs=($(get_tabs))
    local current_index=$CURRENT_TAB_INDEX
    local tab_id="${tabs[$current_index]}"
    curl -s http://localhost:9222/json/list | jq -r ".[] | select(.id == \"$tab_id\") | .url"
}

# Function to find tab index by URL
find_tab_index_by_url() {
    local target_url="$1"
    local tabs=($(get_tabs))
    
    for i in "${!tabs[@]}"; do
        local tab_url=$(curl -s http://localhost:9222/json/list | jq -r ".[] | select(.id == \"${tabs[$i]}\") | .url")
        if [[ "$tab_url" == "$target_url" ]]; then
            echo $i
            return
        fi
    done
    echo -1
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
    # Since /json/active is unreliable, we'll use a different approach
    # For now, let's just return the first tab ID as a fallback
    get_tabs | head -1
}

# Function to get current tab index
get_current_tab_index() {
    # Since we can't reliably determine the current tab, 
    # we'll use a simple counter approach
    if [ -z "$CURRENT_TAB_INDEX" ]; then
        CURRENT_TAB_INDEX=0
    fi
    echo $CURRENT_TAB_INDEX
}

# Function to switch to next URL
switch_to_next_url() {
    local urls=($(get_urls_from_config))
    local current_url=$(get_current_url)
    local current_url_index=-1
    
    # Find current URL in the config list
    for i in "${!urls[@]}"; do
        if [[ "${urls[$i]}" == "$current_url" ]]; then
            current_url_index=$i
            break
        fi
    done
    
    # If current URL not found, start from beginning
    if [ $current_url_index -eq -1 ]; then
        current_url_index=0
    fi
    
    # Calculate next URL index
    local next_url_index=$(( (current_url_index + 1) % ${#urls[@]} ))
    local next_url="${urls[$next_url_index]}"
    
    echo "Current URL: $current_url (index: $current_url_index)"
    echo "Switching to URL: $next_url (index: $next_url_index)"
    
    # Find the tab with the next URL
    local target_tab_index=$(find_tab_index_by_url "$next_url")
    
    if [ $target_tab_index -eq -1 ]; then
        echo "ERROR: Could not find tab with URL: $next_url"
        return 1
    fi
    
    local tabs=($(get_tabs))
    local target_tab_id="${tabs[$target_tab_index]}"
    
    echo "Found target tab at index $target_tab_index (ID: $target_tab_id)"
    
    # Switch to the target tab
    activate_tab "$target_tab_id"
    CURRENT_TAB_INDEX=$target_tab_index
    
    # Small delay to ensure switch completes
    sleep 0.5
    
    echo "Tab switch successful - now on tab $target_tab_index with URL: $next_url"
    return 0
}

# Function to refresh current tab
refresh_current_tab() {
    local tabs=($(get_tabs))
    local current_index=$CURRENT_TAB_INDEX
    local tab_id="${tabs[$current_index]}"
    local current_url=$(get_current_url)
    echo "Refreshing current tab $current_index (ID: $tab_id, URL: $current_url)"
    reload_tab "$tab_id"
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
    echo "=== Turn $TURN ==="
    echo "Current tab index before switch: $CURRENT_TAB_INDEX"
    
    # Show debug info every few turns
    if [ $((TURN % 3)) -eq 1 ]; then
        show_all_tabs
    fi
    
    # Switch to next URL
    if ! switch_to_next_url; then
        echo "ERROR: Failed to switch URL, exiting"
        exit 1
    fi
    
    echo "Current tab index after switch: $CURRENT_TAB_INDEX"
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