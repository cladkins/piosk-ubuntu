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

echo -e "${INFO}Detecting Ubuntu version and display manager...${RESET}"
# Detect Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs)
echo -e "${DEBUG}Ubuntu version: $UBUNTU_VERSION${RESET}"

# Detect display manager
if systemctl is-active --quiet gdm3; then
    DISPLAY_MANAGER="gdm3"
elif systemctl is-active --quiet lightdm; then
    DISPLAY_MANAGER="lightdm"
elif systemctl is-active --quiet sddm; then
    DISPLAY_MANAGER="sddm"
else
    DISPLAY_MANAGER="unknown"
fi
echo -e "${DEBUG}Display manager: $DISPLAY_MANAGER${RESET}"

echo -e "${INFO}Configuring autologin for Ubuntu...${RESET}"
# Configure auto-login based on display manager
case $DISPLAY_MANAGER in
    "gdm3")
        echo -e "${DEBUG}Configuring GDM3 autologin...${RESET}"
        # Create GDM3 autologin configuration
        mkdir -p /etc/gdm3
        cat > /etc/gdm3/custom.conf << EOF
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=$SUDO_USER
EOF
        ;;
    "lightdm")
        echo -e "${DEBUG}Configuring LightDM autologin...${RESET}"
        # Configure LightDM autologin
        mkdir -p /etc/lightdm
        cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=$SUDO_USER
autologin-user-timeout=0
EOF
        ;;
    "sddm")
        echo -e "${DEBUG}Configuring SDDM autologin...${RESET}"
        # Configure SDDM autologin
        mkdir -p /etc/sddm.conf.d
        cat > /etc/sddm.conf.d/autologin.conf << EOF
[Autologin]
User=$SUDO_USER
Session=ubuntu.desktop
EOF
        ;;
    *)
        echo -e "${WARNING}Unknown display manager. Please configure autologin manually.${RESET}"
        ;;
esac

echo -e "${INFO}Installing dependencies...${RESET}"
# Update package list
apt update

# Install dependencies
apt install -y git jq nodejs npm chromium-browser

# Install wtype for keyboard simulation (Ubuntu package)
if ! command -v wtype >/dev/null 2>&1; then
    echo -e "${DEBUG}Installing wtype from source...${RESET}"
    apt install -y build-essential libxkbcommon-dev libwayland-dev libinput-dev
    git clone https://github.com/atx/wtype.git /tmp/wtype
    cd /tmp/wtype
    make
    make install
    cd -
    rm -rf /tmp/wtype
fi

echo -e "${INFO}Cloning repository...${RESET}"
git clone https://github.com/debloper/piosk.git "$PIOSK_DIR"
cd "$PIOSK_DIR"

echo -e "${INFO}Installing npm dependencies...${RESET}"
npm i

echo -e "${INFO}Restoring configurations...${RESET}"
if [ ! -f /opt/piosk/config.json ]; then
    if [ -f /opt/piosk.config.bak ]; then
        mv /opt/piosk.config.bak /opt/piosk/config.json
    else
        mv config.json.sample config.json
    fi
fi

echo -e "${INFO}Installing PiOSK services...${RESET}"
PI_USER="$SUDO_USER"
PI_SUID=$(id -u "$SUDO_USER")
PI_HOME=$(eval echo ~"$SUDO_USER")

# Create Ubuntu-compatible service templates
sed -e "s|PI_HOME|$PI_HOME|g" \
    -e "s|PI_SUID|$PI_SUID|g" \
    -e "s|PI_USER|$PI_USER|g" \
    "$PIOSK_DIR/services/piosk-runner-ubuntu.template" > "/etc/systemd/system/piosk-runner.service"

sed -e "s|PI_HOME|$PI_HOME|g" \
    -e "s|PI_SUID|$PI_SUID|g" \
    -e "s|PI_USER|$PI_USER|g" \
    "$PIOSK_DIR/services/piosk-switcher-ubuntu.template" > "/etc/systemd/system/piosk-switcher.service"

cp "$PIOSK_DIR/services/piosk-dashboard.template" /etc/systemd/system/piosk-dashboard.service

echo -e "${INFO}Reloading systemd daemons...${RESET}"
systemctl daemon-reload

echo -e "${INFO}Enabling PiOSK daemons...${RESET}"
systemctl enable piosk-runner
systemctl enable piosk-switcher
systemctl enable piosk-dashboard

echo -e "${INFO}Starting PiOSK daemons...${RESET}"
# The runner and switcher services are meant to be started after reboot
# systemctl start piosk-runner
# systemctl start piosk-switcher
systemctl start piosk-dashboard

echo -e "${CALLOUT}\nPiOSK is now installed on Ubuntu.${RESET}"
echo -e "Visit either of these links to access PiOSK dashboard:"
echo -e "\t- ${INFO}\033[0;32mhttp://$(hostname)/${RESET} or,"
echo -e "\t- ${INFO}http://$(hostname -I | cut -d " " -f1)/${RESET}"
echo -e "Configure links to shuffle; then apply changes to reboot."
echo -e "${WARNING}\033[0;31mThe kiosk mode will launch on next startup.${RESET}"
echo -e "${INFO}Display manager configured: $DISPLAY_MANAGER${RESET}" 