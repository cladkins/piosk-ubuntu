#!/bin/bash

echo "PiOSK for Ubuntu - Installation Script"
echo "======================================"
echo ""
echo "This script will install PiOSK on your Ubuntu system."
echo "It will:"
echo "- Install required dependencies"
echo "- Configure auto-login for your display manager"
echo "- Set up PiOSK services"
echo "- Start the web dashboard"
echo ""
echo "Press Enter to continue or Ctrl+C to cancel..."
read

# Download and run the setup script
curl -sSL https://raw.githubusercontent.com/debloper/piosk/main/scripts/setup-ubuntu.sh | sudo bash -

echo ""
echo "Installation complete!"
echo "Visit http://$(hostname -I | cut -d ' ' -f1)/ to access the PiOSK dashboard."
echo "The kiosk mode will start on the next reboot." 