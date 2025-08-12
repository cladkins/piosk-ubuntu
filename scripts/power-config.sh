#!/bin/bash

# PiOSK Power Management Configuration Script
# This script configures power management settings to prevent screen saver,
# auto logout, and display blanking in kiosk mode.

echo "Configuring power management for PiOSK kiosk mode..."

# Wait for the desktop environment to be fully loaded
sleep 10

# Function to set gsettings with error handling
set_gsetting() {
    local schema="$1"
    local key="$2"
    local value="$3"
    
    if command -v gsettings >/dev/null 2>&1; then
        echo "Setting $schema $key to $value"
        gsettings set "$schema" "$key" "$value" 2>/dev/null || echo "Failed to set $schema $key"
    else
        echo "gsettings not available"
    fi
}

# Function to set dconf with error handling
set_dconf() {
    local key="$1"
    local value="$2"
    
    if command -v dconf >/dev/null 2>&1; then
        echo "Setting dconf $key to $value"
        dconf write "$key" "$value" 2>/dev/null || echo "Failed to set dconf $key"
    else
        echo "dconf not available"
    fi
}

# GNOME/Unity Power Management Settings
echo "Configuring GNOME/Unity power management..."

# Disable screen saver
set_gsetting "org.gnome.desktop.screensaver" "idle-activation-enabled" "false"
set_gsetting "org.gnome.desktop.screensaver" "lock-enabled" "false"
set_gsetting "org.gnome.desktop.screensaver" "lock-delay" "uint32 0"

# Disable power management
set_gsetting "org.gnome.settings-daemon.plugins.power" "sleep-inactive-ac-type" "0"
set_gsetting "org.gnome.settings-daemon.plugins.power" "sleep-inactive-battery-type" "0"
set_gsetting "org.gnome.settings-daemon.plugins.power" "sleep-display-ac" "0"
set_gsetting "org.gnome.settings-daemon.plugins.power" "sleep-display-battery" "0"
set_gsetting "org.gnome.settings-daemon.plugins.power" "idle-dim" "false"
set_gsetting "org.gnome.settings-daemon.plugins.power" "power-button-action" "'nothing'"

# Disable session management
set_gsetting "org.gnome.desktop.session" "idle-delay" "uint32 0"
set_gsetting "org.gnome.desktop.session" "auto-save-session" "false"

# Disable automatic logout
set_gsetting "org.gnome.desktop.session" "idle-delay" "uint32 0"

# KDE Plasma Power Management Settings
echo "Configuring KDE Plasma power management..."

# Disable screen saver
set_dconf "/org/kde/ksmserver/general/confirmLogout" "false"
set_dconf "/org/kde/ksmserver/general/excludeApps" "['piosk']"

# Disable power management
set_dconf "/org/kde/powerdevil/profiles/AC/DPMSControl" "0"
set_dconf "/org/kde/powerdevil/profiles/AC/DPMSStandby" "0"
set_dconf "/org/kde/powerdevil/profiles/AC/DPMSSuspend" "0"
set_dconf "/org/kde/powerdevil/profiles/AC/DPMSOff" "0"
set_dconf "/org/kde/powerdevil/profiles/AC/autoSuspend" "0"
set_dconf "/org/kde/powerdevil/profiles/AC/autoSuspendWhenLidClosed" "false"

set_dconf "/org/kde/powerdevil/profiles/Battery/DPMSControl" "0"
set_dconf "/org/kde/powerdevil/profiles/Battery/DPMSStandby" "0"
set_dconf "/org/kde/powerdevil/profiles/Battery/DPMSSuspend" "0"
set_dconf "/org/kde/powerdevil/profiles/Battery/DPMSOff" "0"
set_dconf "/org/kde/powerdevil/profiles/Battery/autoSuspend" "0"
set_dconf "/org/kde/powerdevil/profiles/Battery/autoSuspendWhenLidClosed" "false"

# XFCE Power Management Settings
echo "Configuring XFCE power management..."

# Disable screen saver
set_dconf "/org/xfce/mousepad/preferences/view/auto-indent" "false"
set_dconf "/org/xfce/mousepad/preferences/view/highlight-current-line" "false"

# Disable power management
set_dconf "/org/xfce/power-manager/inactivity-on-ac" "0"
set_dconf "/org/xfce/power-manager/inactivity-on-battery" "0"
set_dconf "/org/xfce/power-manager/sleep-on-ac" "0"
set_dconf "/org/xfce/power-manager/sleep-on-battery" "0"
set_dconf "/org/xfce/power-manager/blank-on-ac" "0"
set_dconf "/org/xfce/power-manager/blank-on-battery" "0"

# X11 Screen Saver Settings (fallback)
echo "Configuring X11 screen saver settings..."

if command -v xset >/dev/null 2>&1; then
    echo "Disabling X11 screen saver..."
    xset s off 2>/dev/null || echo "Failed to disable X11 screen saver"
    xset s noblank 2>/dev/null || echo "Failed to disable X11 screen blanking"
    xset -dpms 2>/dev/null || echo "Failed to disable X11 DPMS"
else
    echo "xset not available"
fi

# Disable systemd-logind idle session handling
echo "Configuring systemd-logind settings..."

if command -v loginctl >/dev/null 2>&1; then
    echo "Disabling systemd-logind idle session handling..."
    loginctl set-user-property $USER IdleAction ignore 2>/dev/null || echo "Failed to set IdleAction"
    loginctl set-user-property $USER IdleActionUSec 0 2>/dev/null || echo "Failed to set IdleActionUSec"
else
    echo "loginctl not available"
fi

# Create a systemd user service to keep settings persistent
echo "Creating persistent power management service..."

mkdir -p /home/$USER/.config/systemd/user

cat > /home/$USER/.config/systemd/user/piosk-power-management.service << EOF
[Unit]
Description=PiOSK Power Management
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=/opt/piosk/scripts/power-config.sh
RemainAfterExit=yes

[Install]
WantedBy=graphical-session.target
EOF

# Enable the user service
systemctl --user enable piosk-power-management.service 2>/dev/null || echo "Failed to enable user service"

echo "Power management configuration complete!"
echo "Screen saver, auto logout, and power management have been disabled for kiosk mode." 