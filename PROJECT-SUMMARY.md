# PiOSK Ubuntu - Project Summary

## Overview

This project is an Ubuntu adaptation of the original [PiOSK](https://github.com/debloper/piosk) project by [Soumya Deb](https://github.com/debloper). The original PiOSK was designed for Raspberry Pi systems, and this fork has been modified to work seamlessly on Ubuntu desktop systems.

## Key Accomplishments

### 1. Ubuntu System Integration
- **Automatic Display Manager Detection**: Automatically detects and configures GDM3, LightDM, or SDDM
- **Autologin Configuration**: Sets up automatic login for the user's display manager
- **Autostart Integration**: Uses desktop autostart entries for better X11 authorization
- **Systemd Services**: Proper systemd service integration for reliability

### 2. X11 Authorization Fixes
- **Autostart Approach**: Replaced problematic systemd services with autostart entries
- **Snap Chromium Support**: Prioritizes Ubuntu's snap Chromium for better compatibility
- **Environment Handling**: Proper DISPLAY, XAUTHORITY, and XDG_RUNTIME_DIR setup

### 3. Web Dashboard Improvements
- **Nginx Reverse Proxy**: Secure web interface on port 80
- **Port 3000 Backend**: Dashboard runs on port 3000 to avoid permission issues
- **Automatic Dependency Installation**: npm dependencies installed automatically during setup

### 4. Installation Process
- **Single Command Installation**: `curl -sSL https://raw.githubusercontent.com/cladkins/piosk-ubuntu/main/scripts/setup.sh | sudo bash -`
- **Automatic Dependency Management**: Installs all required packages and dependencies
- **Ownership and Permissions**: Proper file ownership and permissions setup
- **Complete System Integration**: Configures autologin, services, and autostart

### 5. Documentation and Credits
- **Updated README**: Comprehensive documentation with Ubuntu-specific instructions
- **Proper Attribution**: Clear credits to the original author and project
- **Troubleshooting Guide**: Ubuntu-specific troubleshooting information
- **Cleanup Script**: Complete uninstallation process

## Technical Changes from Original

### Files Modified/Created
- `scripts/setup.sh` - Complete Ubuntu setup script
- `scripts/runner.sh` - Simplified Chromium runner
- `scripts/runner-wrapper.sh` - X11 authorization wrapper
- `scripts/cleanup.sh` - Complete cleanup script
- `services/piosk-*.template` - Ubuntu-optimized service templates
- `index.js` - Changed port from 80 to 3000
- `README.md` - Comprehensive Ubuntu documentation
- `package.json` - Updated metadata and credits

### Key Technical Solutions
1. **X11 Authorization**: Used autostart entries instead of systemd services
2. **Port Binding**: Used nginx reverse proxy to avoid port 80 permission issues
3. **Chromium Compatibility**: Prioritized snap Chromium over system Chromium
4. **Dependency Management**: Automatic npm installation during setup
5. **Service Management**: Proper systemd service configuration

## Installation Process

The installation process now:
1. Detects the display manager (GDM3/LightDM/SDDM)
2. Configures autologin for the user
3. Downloads and installs all files
4. Installs npm dependencies
5. Installs and configures nginx
6. Creates autostart entries
7. Sets up systemd services
8. Configures proper ownership and permissions

## Result

A fully functional kiosk system that:
- Starts automatically on boot
- Provides web-based configuration interface
- Cycles through configured URLs
- Works reliably on Ubuntu systems
- Requires no manual intervention after installation

## Credits

- **Original Project**: [PiOSK by Soumya Deb](https://github.com/debloper/piosk)
- **Original Author**: [Soumya Deb](https://github.com/debloper)
- **Ubuntu Adaptation**: [cladkins](https://github.com/cladkins)
- **License**: MPL-2.0 (same as original) 