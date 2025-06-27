# Ubuntu Adaptation Changes

This document outlines the changes made to adapt the original PiOSK project for Ubuntu systems.

## New Files Created

### Setup and Installation
- `scripts/setup-ubuntu.sh` - Ubuntu-compatible installation script
- `scripts/cleanup-ubuntu.sh` - Ubuntu-compatible uninstallation script
- `install-ubuntu.sh` - Simple installation wrapper script

### Service Templates
- `services/piosk-runner-ubuntu.template` - Ubuntu systemd service for Chromium runner
- `services/piosk-switcher-ubuntu.template` - Ubuntu systemd service for tab switcher

### Scripts
- `scripts/runner-ubuntu.sh` - Ubuntu-optimized Chromium launcher
- `scripts/switcher-ubuntu.sh` - Ubuntu-compatible tab switcher

### Documentation
- `README-UBUNTU.md` - Comprehensive Ubuntu-specific documentation
- `UBUNTU-CHANGES.md` - This file documenting changes

## Key Changes Made

### 1. Package Management
- **Original**: Uses Raspberry Pi OS specific packages
- **Ubuntu**: Uses Ubuntu's `apt` package manager
- **Changes**: 
  - Added `apt update` before installation
  - Changed package names to Ubuntu equivalents
  - Added fallback installation for `wtype` from source

### 2. Display Manager Support
- **Original**: Raspberry Pi OS specific auto-login
- **Ubuntu**: Multi-display manager support
- **Changes**:
  - Auto-detection of GDM3, LightDM, and SDDM
  - Automatic configuration for each display manager
  - Proper auto-login setup for Ubuntu desktop environments

### 3. Systemd Services
- **Original**: Raspberry Pi specific service templates
- **Ubuntu**: Ubuntu-optimized service templates
- **Changes**:
  - Added `graphical-session.target` dependencies
  - Added `DBUS_SESSION_BUS_ADDRESS` environment variable
  - Increased sleep times for better Ubuntu compatibility
  - Added `RestartSec` for better service management

### 4. Browser Launch Parameters
- **Original**: Raspberry Pi optimized Chromium flags
- **Ubuntu**: Ubuntu-optimized Chromium flags
- **Changes**:
  - Added `--no-sandbox` and `--disable-setuid-sandbox` for better compatibility
  - Added `--disable-dev-shm-usage` for shared memory issues
  - Added `--disable-web-security` for kiosk mode
  - Added display availability check before launch

### 5. Tab Switching
- **Original**: Uses `wtype` only
- **Ubuntu**: Fallback to `xdotool` if `wtype` unavailable
- **Changes**:
  - Added dynamic user ID detection
  - Added fallback keyboard simulation method
  - Increased wait times for better reliability

### 6. Error Handling
- **Original**: Basic error handling
- **Ubuntu**: Enhanced error handling for Ubuntu systems
- **Changes**:
  - Added display manager detection
  - Added graceful fallbacks for missing tools
  - Better service status checking

## Compatibility Notes

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
curl -sSL https://raw.githubusercontent.com/debloper/piosk/main/scripts/setup-ubuntu.sh | sudo bash -
```

### Method 2: Clone and Install
```bash
git clone https://github.com/debloper/piosk.git
cd piosk
sudo ./scripts/setup-ubuntu.sh
```

### Method 3: Simple Installer
```bash
wget https://raw.githubusercontent.com/debloper/piosk/main/install-ubuntu.sh
chmod +x install-ubuntu.sh
./install-ubuntu.sh
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