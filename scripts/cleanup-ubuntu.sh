#!/bin/bash
set -e

# Installation directory
PIOSK_DIR="/opt/piosk"

RESET='\033[0m'      # Reset to default
ERROR='\033[1;31m'   # Bold Red
SUCCESS='\033[1;32m' # Bold Green
WARNING='\033[1;33m' # Bold Yellow
INFO='\033[1;34m'    # Bold Blue
CALLOUT='\033[1;35m' # Bold Magenta
DEBUG='\033[1;36m'   # Bold Cyan

echo -e "${INFO}Checking superuser privileges...${RESET}"
if [ "$EUID" -ne 0 ]; then
  echo -e "${DEBUG}Escalating privileges as superuser...${RESET}"

  sudo "$0" "$@" # Re-execute the script as superuser
  exit $?  # Exit with the status of the sudo command
fi

echo -e "${INFO}Stopping PiOSK services...${RESET}"
systemctl stop piosk-runner 2>/dev/null || true
systemctl stop piosk-switcher 2>/dev/null || true
systemctl stop piosk-dashboard 2>/dev/null || true

echo -e "${INFO}Disabling PiOSK services...${RESET}"
systemctl disable piosk-runner 2>/dev/null || true
systemctl disable piosk-switcher 2>/dev/null || true
systemctl disable piosk-dashboard 2>/dev/null || true

echo -e "${INFO}Removing PiOSK service files...${RESET}"
rm -f /etc/systemd/system/piosk-runner.service
rm -f /etc/systemd/system/piosk-switcher.service
rm -f /etc/systemd/system/piosk-dashboard.service

echo -e "${INFO}Reloading systemd daemons...${RESET}"
systemctl daemon-reload

echo -e "${INFO}Backing up configuration...${RESET}"
if [ -f "$PIOSK_DIR/config.json" ]; then
    cp "$PIOSK_DIR/config.json" /opt/piosk.config.bak
    echo -e "${SUCCESS}Configuration backed up to /opt/piosk.config.bak${RESET}"
fi

echo -e "${INFO}Removing PiOSK installation...${RESET}"
if [ -d "$PIOSK_DIR" ]; then
    rm -rf "$PIOSK_DIR"
    echo -e "${SUCCESS}PiOSK installation removed${RESET}"
fi

echo -e "${INFO}Cleaning up autologin configuration...${RESET}"
# Remove autologin configurations for different display managers
rm -f /etc/gdm3/custom.conf
rm -f /etc/lightdm/lightdm.conf
rm -f /etc/sddm.conf.d/autologin.conf

echo -e "${CALLOUT}\nPiOSK has been uninstalled from Ubuntu.${RESET}"
echo -e "${INFO}Configuration backup saved to /opt/piosk.config.bak${RESET}"
echo -e "${WARNING}Note: Dependencies (git, jq, nodejs, npm, chromium-browser) were not removed${RESET}"
echo -e "${WARNING}to avoid breaking other applications that may depend on them.${RESET}" 