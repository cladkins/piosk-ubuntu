# PiOSK Power Management Implementation

## Overview

This document describes the power management implementation for PiOSK Ubuntu, which ensures that kiosk displays remain active by disabling screen saver, auto logout, and power management features.

## Problem Statement

The original PiOSK setup did not configure power management settings, which could cause:
- Screen saver activation during kiosk operation
- Automatic user logout due to inactivity
- Display power management (DPMS) turning off the screen
- System sleep/hibernate during kiosk mode
- Session management interfering with kiosk operation

## Solution Architecture

### Multi-Layer Approach

The power management implementation uses a multi-layer approach to ensure maximum compatibility across different Ubuntu desktop environments:

1. **Desktop Environment Specific Settings**
   - GNOME/Unity: gsettings configuration
   - KDE Plasma: dconf configuration
   - XFCE: dconf configuration

2. **X11 Fallback Settings**
   - xset commands for basic screen saver control
   - DPMS (Display Power Management Signaling) control

3. **System-Level Settings**
   - systemd-logind configuration
   - User session management

4. **Persistence Layer**
   - Autostart entries for immediate application
   - Systemd user services for persistence across reboots

## Implementation Details

### 1. Power Configuration Script (`scripts/power-config.sh`)

**Purpose**: Main script that applies all power management settings

**Features**:
- Desktop environment detection and configuration
- Error handling for missing tools
- Comprehensive settings for all major desktop environments
- X11 fallback configuration
- Systemd-logind configuration

**Key Settings Applied**:

#### GNOME/Unity
```bash
# Screen saver
gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
gsettings set org.gnome.desktop.screensaver lock-enabled false

# Power management
gsettings set org.gnome.settings-daemon.plugins.power sleep-display-ac 0
gsettings set org.gnome.settings-daemon.plugins.power sleep-display-battery 0
gsettings set org.gnome.settings-daemon.plugins.power idle-dim false

# Session management
gsettings set org.gnome.desktop.session idle-delay 0
```

#### KDE Plasma
```bash
# Power management
dconf write /org/kde/powerdevil/profiles/AC/DPMSControl 0
dconf write /org/kde/powerdevil/profiles/AC/autoSuspend 0
dconf write /org/kde/powerdevil/profiles/Battery/DPMSControl 0
dconf write /org/kde/powerdevil/profiles/Battery/autoSuspend 0
```

#### XFCE
```bash
# Power management
dconf write /org/xfce/power-manager/inactivity-on-ac 0
dconf write /org/xfce/power-manager/blank-on-ac 0
dconf write /org/xfce/power-manager/sleep-on-ac 0
```

#### X11 Fallback
```bash
# Disable screen saver and DPMS
xset s off
xset s noblank
xset -dpms
```

### 2. Autostart Integration

**Files Created**:
- `/home/$USER/.config/autostart/piosk-power-config.desktop`

**Purpose**: Ensures power settings are applied every time the user logs in

**Execution**: Runs automatically after desktop environment loads

### 3. Systemd User Service

**File Created**: `/home/$USER/.config/systemd/user/piosk-power-management.service`

**Purpose**: Provides persistence and reliability for power settings

**Features**:
- Runs after graphical session starts
- One-shot service that applies settings and remains active
- Automatically enabled during installation

### 4. Manual Application Script (`scripts/apply-power-settings.sh`)

**Purpose**: Allows users to apply power settings immediately without rebooting

**Usage**: Run as regular user from graphical session

**Features**:
- Validation checks (non-root, graphical session)
- Error handling and user feedback
- Integration with main power configuration script

### 5. Testing Script (`scripts/test-power-settings.sh`)

**Purpose**: Verifies that power settings have been applied correctly

**Features**:
- Tests all desktop environment settings
- Provides visual feedback (✓/✗/?) for each setting
- Identifies which settings need attention
- Suggests corrective actions

## Installation Integration

### Setup Script Modifications

The main setup script (`scripts/setup.sh`) has been enhanced to:

1. **Create Power Configuration Autostart Entry**
   - Adds `piosk-power-config.desktop` to autostart
   - Ensures proper ownership and permissions

2. **Automatic Script Installation**
   - All power management scripts are installed to `/opt/piosk/scripts/`
   - Scripts are made executable during installation

### Cleanup Script Modifications

The cleanup script (`scripts/cleanup.sh`) has been enhanced to:

1. **Remove Power Management Files**
   - Removes autostart entries
   - Stops and disables systemd user services
   - Cleans up configuration files

## Usage Instructions

### Automatic Application

Power settings are automatically applied during:
- Initial PiOSK installation
- System boot (via autostart)
- User login (via systemd user service)

### Manual Application

```bash
# Apply settings immediately
/opt/piosk/scripts/apply-power-settings.sh

# Test current settings
/opt/piosk/scripts/test-power-settings.sh

# Check specific settings
gsettings get org.gnome.desktop.screensaver idle-activation-enabled
```

### Verification

The test script provides comprehensive verification:

```bash
/opt/piosk/scripts/test-power-settings.sh
```

Expected output shows ✓ marks for all settings.

## Troubleshooting

### Common Issues

1. **Settings Not Applied**
   - Run `/opt/piosk/scripts/apply-power-settings.sh`
   - Check if running as regular user (not root)
   - Ensure graphical session is active

2. **Settings Not Persisting**
   - Check systemd user service: `systemctl --user status piosk-power-management.service`
   - Verify autostart entry exists: `ls ~/.config/autostart/piosk-power-config.desktop`

3. **Desktop Environment Not Supported**
   - Check test script output for unsupported environments
   - X11 fallback should still work in most cases

4. **Permission Issues**
   - Ensure scripts are executable: `chmod +x /opt/piosk/scripts/*.sh`
   - Check file ownership: `ls -la /opt/piosk/scripts/`

### Debugging

```bash
# Check script execution
tail -f ~/.xsession-errors

# Check systemd user service logs
journalctl --user -u piosk-power-management.service

# Test individual settings
gsettings list-recursively org.gnome.desktop.screensaver
dconf list /org/kde/powerdevil/profiles/AC/
```

## Compatibility

### Supported Desktop Environments

- **GNOME 3.x/4.x**: Full support via gsettings
- **Unity**: Full support via gsettings
- **KDE Plasma**: Full support via dconf
- **XFCE**: Full support via dconf
- **Other X11 environments**: Basic support via xset

### Ubuntu Versions

- **Ubuntu 18.04 LTS**: Full support
- **Ubuntu 20.04 LTS**: Full support
- **Ubuntu 22.04 LTS**: Full support
- **Ubuntu 24.04 LTS**: Full support

### Dependencies

- `gsettings`: GNOME/Unity configuration
- `dconf`: KDE/XFCE configuration
- `xset`: X11 screen saver control
- `systemctl`: Systemd service management
- `loginctl`: Session management

## Security Considerations

### User Permissions

- All scripts run as regular user (not root)
- Uses user-specific configuration paths
- Respects existing user permissions

### Configuration Scope

- Only affects power management settings
- Does not modify system-wide configurations
- Settings are user-specific and reversible

### Reversibility

- All settings can be reverted via cleanup script
- Individual settings can be manually restored
- No permanent system modifications

## Future Enhancements

### Potential Improvements

1. **Wayland Support**
   - Add Wayland-specific power management
   - Integrate with wlroots-based compositors

2. **Configuration Options**
   - Allow users to customize power settings
   - Add web dashboard integration for power management

3. **Advanced Features**
   - Schedule-based power management
   - Network-based wake-up capabilities
   - Integration with hardware sensors

4. **Monitoring**
   - Real-time power management status
   - Logging and alerting capabilities
   - Performance impact monitoring

## Conclusion

The power management implementation provides a comprehensive solution for ensuring PiOSK displays remain active. The multi-layer approach ensures compatibility across different Ubuntu desktop environments while providing fallback options for maximum reliability.

The implementation is designed to be:
- **Automatic**: No manual intervention required
- **Persistent**: Settings survive reboots and session changes
- **Reversible**: Easy to restore normal power management
- **Compatible**: Works with all major Ubuntu desktop environments
- **Maintainable**: Clear documentation and troubleshooting guides 