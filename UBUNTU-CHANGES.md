# PiOSK for Ubuntu - Project Overview

This document outlines the Ubuntu-focused PiOSK project, which transforms Ubuntu machines into kiosk mode displays.

## Project Structure

### Core Files
- `scripts/setup.sh` - Main installation script
- `scripts/cleanup.sh` - Uninstallation script
- `scripts/runner.sh` - Chromium launcher script
- `scripts/switcher.sh` - Tab switching script
- `install.sh` - Simple installation wrapper script

### Service Templates
- `services/piosk-runner.template` - Systemd service for Chromium runner
- `services/piosk-switcher.template` - Systemd service for tab switcher
- `services/piosk-dashboard.template` - Systemd service for web dashboard

### Documentation
- `README.md` - Main project documentation
- `UBUNTU-CHANGES.md` - This file documenting project structure

## Key Features

### 1. Package Management
- Uses Ubuntu's `apt` package manager
- Installs `git`, `jq`, `nodejs`, `npm`, `chromium-browser`
- Builds `wtype` from source if not available
- Includes fallback to `xdotool` for keyboard simulation

### 2. Display Manager Support
- Auto-detection of GDM3, LightDM, and SDDM
- Automatic configuration for each display manager
- Proper auto-login setup for Ubuntu desktop environments

### 3. Systemd Services
- Enhanced service templates with `graphical-session.target` dependencies
- Added `DBUS_SESSION_BUS_ADDRESS` environment variable
- Increased sleep times for better Ubuntu compatibility
- Added `RestartSec` for better service management

### 4. Browser Launch Parameters
- Ubuntu-optimized Chromium flags
- Added `--no-sandbox` and `--disable-setuid-sandbox` for compatibility
- Added `--disable-dev-shm-usage` for shared memory issues
- Added `--disable-web-security` for kiosk mode
- Added display availability check before launch

### 5. Tab Switching
- Dynamic user ID detection
- Fallback keyboard simulation methods
- Increased wait times for better reliability

### 6. Error Handling
- Display manager detection
- Graceful fallbacks for missing tools
- Better service status checking

## Compatibility

### Supported Ubuntu Versions
- Ubuntu 18.04 LTS and newer
- All major desktop environments (GNOME, KDE, XFCE, etc.)
- Both X11 and Wayland display systems

### Display Manager Support
- **GDM3**: Primary GNOME display manager
- **LightDM**: Used by XFCE and other lightweight environments
- **SDDM**: KDE Plasma display manager

### Dependencies
- `git`, `jq`, `nodejs`, `npm` - Standard Ubuntu packages
- `chromium-browser` - Ubuntu's Chromium package
- `wtype` - Built from source if not available
- `xdotool` - Fallback for keyboard simulation

## Installation Methods

### Method 1: Direct Download
```bash
curl -sSL https://raw.githubusercontent.com/cladkins/piosk-ubuntu/main/scripts/setup.sh | sudo bash -
```

### Method 2: Clone and Install
```bash
git clone https://github.com/cladkins/piosk-ubuntu.git
cd piosk-ubuntu
sudo ./scripts/setup.sh
```

### Method 3: Simple Installer
```bash
wget https://raw.githubusercontent.com/cladkins/piosk-ubuntu/main/install.sh
chmod +x install.sh
./install.sh
```

## Testing Recommendations

1. **Fresh Ubuntu Installation**: Test on clean Ubuntu 20.04/22.04 systems
2. **Different Desktop Environments**: Test with GNOME, KDE, and XFCE
3. **Display Managers**: Verify auto-login works with GDM3, LightDM, and SDDM
4. **Network Access**: Ensure web dashboard is accessible from other devices
5. **Service Reliability**: Test service restart and recovery scenarios

## Future Improvements

1. **Wayland Support**: Better integration with Wayland display system
2. **Package Dependencies**: Consider using snap or flatpak for better isolation
3. **Configuration UI**: Enhanced web dashboard for Ubuntu-specific settings
4. **Logging**: Better logging and debugging capabilities
5. **Security**: Additional security hardening for production environments 