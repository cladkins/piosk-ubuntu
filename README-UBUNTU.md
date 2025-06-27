# PiOSK for Ubuntu

**One-shot set up Ubuntu in kiosk mode as a webpage shuffler, with a web interface for management.**

This is an Ubuntu-compatible version of the original [PiOSK](https://github.com/debloper/piosk) project, adapted to work with Ubuntu desktop systems.

## Overview

PiOSK for Ubuntu transforms your Ubuntu machine into a kiosk mode display that cycles through web pages automatically. It includes a web-based dashboard for easy management of the displayed URLs.

## Features

- **Automatic Setup**: Single script installation
- **Web Dashboard**: Manage URLs through a web interface
- **Auto-login**: Configures automatic login for your display manager
- **Tab Rotation**: Automatically cycles through configured web pages
- **Systemd Integration**: Runs as system services for reliability
- **Multiple Display Manager Support**: Works with GDM3, LightDM, and SDDM

## System Requirements

- Ubuntu 18.04 LTS or newer
- Desktop environment (GNOME, KDE, XFCE, etc.)
- Internet connection for initial setup
- At least 2GB RAM recommended

## Installation

### Quick Install

Run the following command in your terminal:

```bash
curl -sSL https://raw.githubusercontent.com/debloper/piosk/main/scripts/setup-ubuntu.sh | sudo bash -
```

### Manual Install

1. Clone the repository:
```bash
git clone https://github.com/debloper/piosk.git
cd piosk
```

2. Run the Ubuntu setup script:
```bash
sudo ./scripts/setup-ubuntu.sh
```

## Configuration

### Basic Setup

1. After installation, visit `http://<your-ubuntu-ip>/` from any device on your network
2. You'll see the PiOSK dashboard with sample URLs
3. Add, remove, or modify the URLs as needed (at least 1 URL is required)
4. Click the `APPLY ⏻` button to apply changes and reboot
5. After reboot, the kiosk mode will start automatically

### Advanced Configuration

The configuration file is located at `/opt/piosk/config.json`. You can edit it directly or use the web interface.

Example configuration:
```json
{
    "urls": [
        {
            "url": "https://example.com"
        },
        {
            "url": "https://another-site.com"
        }
    ]
}
```

## Display Manager Support

The setup script automatically detects and configures your display manager:

- **GDM3** (GNOME): Most common on Ubuntu
- **LightDM**: Used by XFCE and some other desktop environments
- **SDDM**: Used by KDE Plasma

## Troubleshooting

### Common Issues

1. **Display not working**: Ensure you're logged into a desktop session
2. **Web dashboard not accessible**: Check if port 80 is available
3. **Chromium not starting**: Verify display permissions and X11 setup
4. **Auto-login not working**: Check your display manager configuration

### Manual Display Manager Configuration

If auto-login doesn't work automatically, you can configure it manually:

#### GDM3
```bash
sudo nano /etc/gdm3/custom.conf
```
Add:
```ini
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=yourusername
```

#### LightDM
```bash
sudo nano /etc/lightdm/lightdm.conf
```
Add:
```ini
[SeatDefaults]
autologin-user=yourusername
autologin-user-timeout=0
```

#### SDDM
```bash
sudo nano /etc/sddm.conf.d/autologin.conf
```
Add:
```ini
[Autologin]
User=yourusername
Session=ubuntu.desktop
```

### Service Management

Check service status:
```bash
sudo systemctl status piosk-dashboard
sudo systemctl status piosk-runner
sudo systemctl status piosk-switcher
```

Restart services:
```bash
sudo systemctl restart piosk-dashboard
sudo systemctl restart piosk-runner
sudo systemctl restart piosk-switcher
```

## Uninstallation

To remove PiOSK from your Ubuntu system:

```bash
sudo /opt/piosk/scripts/cleanup-ubuntu.sh
```

Or if you've installed manually:
```bash
sudo ./scripts/cleanup-ubuntu.sh
```

## Differences from Raspberry Pi Version

- **Package Management**: Uses Ubuntu's `apt` instead of Raspberry Pi OS packages
- **Display System**: Adapted for Ubuntu's X11/Wayland display system
- **Auto-login**: Supports multiple display managers (GDM3, LightDM, SDDM)
- **Browser**: Uses Ubuntu's Chromium package
- **Dependencies**: Includes Ubuntu-specific dependency installation
- **Service Templates**: Modified systemd services for Ubuntu compatibility

## Security Considerations

- The web dashboard runs on port 80 by default
- Consider changing the port if you have other web services
- The kiosk mode runs with reduced privileges
- Consider disabling unnecessary network services for production use

## Contributing

This is an adaptation of the original PiOSK project. For the main project, visit: https://github.com/debloper/piosk

## License

Same as the original PiOSK project - MPL-2.0

## Support

For Ubuntu-specific issues, please check:
1. Your Ubuntu version and desktop environment
2. Display manager configuration
3. Network connectivity
4. Service logs: `sudo journalctl -u piosk-*`

For general PiOSK issues, refer to the original project's documentation. 