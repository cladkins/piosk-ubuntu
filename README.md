![PiOSK Ubuntu](assets/pioskubuntu.png)

# PiOSK for Ubuntu

**One-shot set up Ubuntu in kiosk mode as a webpage shuffler, with a web interface for management.**

PiOSK transforms your Ubuntu machine into a kiosk mode display that cycles through web pages automatically. It includes a web-based dashboard for easy management of the displayed URLs.

## About This Project

This is an **Ubuntu adaptation** of the original [PiOSK project](https://github.com/debloper/piosk) by [Soumya Deb](https://github.com/debloper). The original PiOSK was designed for Raspberry Pi, and this fork has been modified to work seamlessly on Ubuntu systems.

**Original Project**: [PiOSK by Soumya Deb](https://github.com/debloper/piosk)  
**Original Author**: [Soumya Deb](https://github.com/debloper)  
**License**: MPL-2.0

## Features

- **Automatic Setup**: Single script installation for Ubuntu
- **Web Dashboard**: Manage URLs through a web interface
- **Auto-login**: Configures automatic login for your display manager
- **Tab Rotation**: Automatically cycles through configured web pages
- **Switcher Control**: Web interface to control tab switching timing and enable/disable
- **Systemd Integration**: Runs as system services for reliability
- **Multiple Display Manager Support**: Works with GDM3, LightDM, and SDDM
- **Nginx Reverse Proxy**: Secure web interface on port 80
- **Snap Chromium Support**: Uses Ubuntu's snap Chromium for better compatibility
- **Power Management**: Automatically disables screen saver, auto logout, and power management for kiosk mode

## System Requirements

- Ubuntu 18.04 LTS or newer
- Desktop environment (GNOME, KDE, XFCE, etc.)
- Internet connection for initial setup
- At least 2GB RAM recommended
- Snap Chromium or system Chromium installed

## Quick Installation

Run the following command in your terminal:

```bash
curl -sSL https://raw.githubusercontent.com/cladkins/piosk-ubuntu/main/scripts/setup.sh | sudo bash -
```

This single command will:
- Install all dependencies
- Configure autologin for your display manager
- Set up the kiosk system
- Install and configure nginx
- Create autostart entries
- Install systemd services

## Manual Installation

1. Clone the repository:
```bash
git clone https://github.com/cladkins/piosk-ubuntu.git
cd piosk-ubuntu
```

2. Run the setup script:
```bash
sudo ./scripts/setup.sh
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

## How It Works

1. **Autologin**: The system automatically logs in to the desktop on boot
2. **Autostart**: The kiosk application starts automatically when the desktop loads
3. **Web Dashboard**: Nginx serves the management interface on port 80
4. **Tab Rotation**: Chromium cycles through configured URLs in kiosk mode
5. **Configuration**: Changes made through the web interface are saved and applied on reboot
6. **Power Management**: Screen saver, auto logout, and power management are automatically disabled

## Power Management

PiOSK automatically configures power management settings to ensure the kiosk display remains active:

### What Gets Disabled
- **Screen Saver**: Prevents the screen from going to sleep
- **Auto Logout**: Prevents automatic user logout due to inactivity
- **Display Power Management**: Prevents the display from turning off
- **System Sleep/Hibernate**: Prevents the system from sleeping
- **Session Management**: Disables automatic session saving and restoration

### Desktop Environment Support
The power management configuration works with:
- **GNOME/Unity**: Uses gsettings to configure power management
- **KDE Plasma**: Uses dconf to configure powerdevil settings
- **XFCE**: Uses dconf to configure XFCE power manager
- **X11 Fallback**: Uses xset for basic screen saver control

### Manual Power Settings
If you need to apply power settings manually:

```bash
# Check current power management status
gsettings get org.gnome.desktop.screensaver idle-activation-enabled
```

### Reverting Power Settings
To restore normal power management behavior:

```bash
# Remove PiOSK completely (includes power settings)
sudo /opt/piosk/scripts/cleanup.sh
```

## Switcher Control

PiOSK includes a web-based switcher control interface that allows you to manage tab rotation settings:

### Accessing Switcher Controls
1. Visit the main dashboard at `http://<your-ubuntu-ip>/`
2. Click the "Switcher" button in the navigation bar
3. Or go directly to `http://<your-ubuntu-ip>/switcher.html`

### Switcher Settings
- **Enable/Disable**: Turn the switcher on or off completely
- **Switch Interval**: Set the time between tab switches (1-300 seconds)
- **Refresh Cycle**: Configure how often all tabs are refreshed (1-50 cycles)

### Switcher Controls
- **Start**: Manually start the switcher service
- **Stop**: Manually stop the switcher service
- **Restart**: Restart the switcher service
- **Apply Settings**: Save configuration changes (requires reboot)

### Configuration
Switcher settings are stored in `/opt/piosk/config.json`:

```json
{
    "switcher": {
        "enabled": true,
        "interval": 10,
        "refresh_cycle": 10
    },
    "urls": [...]
}
```

## Troubleshooting

### Common Issues

1. **Display not working**: Ensure you're logged into a desktop session
2. **Web dashboard not accessible**: Check if nginx is running: `sudo systemctl status nginx`
3. **Chromium not starting**: Verify display permissions and X11 setup
4. **Auto-login not working**: Check your display manager configuration
5. **Screen still going to sleep**: Check if power management service is running: `systemctl --user status piosk-power-management.service`
6. **Power settings not persisting**: Check if the systemd user service is enabled: `systemctl --user status piosk-power-management.service`
7. **Dashboard not accessible (502 error)**: Check if the dashboard service is running: `sudo systemctl status piosk-dashboard`
8. **Dashboard service won't start**: Try running manually: `cd /opt/piosk && sudo -u $USER npm start`
9. **Switcher not working**: Check if the switcher service is running: `sudo systemctl status piosk-switcher`
10. **Tabs not switching**: Verify Chromium is running and switcher service is active

### Service Management

Check service status:
```bash
sudo systemctl status piosk-dashboard
sudo systemctl status piosk-runner
sudo systemctl status nginx
```

Restart services:
```bash
sudo systemctl restart piosk-dashboard
sudo systemctl restart piosk-runner
sudo systemctl restart nginx
```

View logs:
```bash
sudo journalctl -u piosk-dashboard -f
sudo journalctl -u piosk-runner -f
```

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

## Uninstallation

To remove PiOSK from your Ubuntu system:

```bash
sudo /opt/piosk/scripts/cleanup.sh
```

Or if you've installed manually:
```bash
sudo ./scripts/cleanup.sh
```

## Security Considerations

- The web dashboard runs on port 80 through nginx
- The kiosk mode runs with reduced privileges
- Consider disabling unnecessary network services for production use
- The system automatically logs in, so ensure physical security

## Differences from Original PiOSK

This Ubuntu version includes several improvements over the original Raspberry Pi version:

- **Ubuntu-specific setup**: Optimized for Ubuntu systems
- **Snap Chromium support**: Better compatibility with Ubuntu's package management
- **Nginx reverse proxy**: More robust web server setup
- **Autostart entries**: Better X11 authorization handling
- **Systemd services**: Improved service management
- **Multiple display manager support**: Works with GDM3, LightDM, and SDDM

## Contributing

This is an Ubuntu adaptation of the original [PiOSK project](https://github.com/debloper/piosk). 

- **Original Project**: [PiOSK by Soumya Deb](https://github.com/debloper/piosk)
- **Original Author**: [Soumya Deb](https://github.com/debloper)
- **This Fork**: [PiOSK Ubuntu by cladkins](https://github.com/cladkins/piosk-ubuntu)

For issues with this Ubuntu version, please check:
1. Your Ubuntu version and desktop environment
2. Display manager configuration
3. Network connectivity
4. Service logs: `sudo journalctl -u piosk-*`

## License

MPL-2.0 - Same license as the original PiOSK project

---

**Credits**: This project is based on the original [PiOSK](https://github.com/debloper/piosk) by [Soumya Deb](https://github.com/debloper), adapted for Ubuntu systems.

![PiOSK Dashboard Web GUI](assets/dashboard.png)
