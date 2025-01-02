#!/bin/bash

# Exit on error
set -e

# Update system packages
apt update -y
apt upgrade -y

# Remove netfilter-persistent (if present)
apt remove netfilter-persistent -y

# Add a new user 'rdpuser' and set the password to 'RDPuser25'
adduser rdpuser --gecos "" --disabled-password
echo "rdpuser:RDPuser25" | chpasswd

# Modify the SSH configuration to allow password authentication
sed -i 's/^#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Install Ubuntu desktop environment (GNOME) and XRDP
apt install ubuntu-desktop -y
apt install xrdp -y

# Configure XRDP to listen on TCP port 3389
sed -i 's/^#port=3389/port=tcp:\/\/:3389/' /etc/xrdp/xrdp.ini

# Allow port 3389 through the firewall
ufw allow 3389/tcp

# Restart XRDP service to apply changes
systemctl restart xrdp

# Add 'rdpuser' to the sudo group
usermod -aG sudo rdpuser

# Output message indicating completion
echo "RDP setup complete. User 'rdpuser' created with password 'RDPuser25' and granted sudo privileges."
echo "Please reboot your system and connect using XRDP on port 3389."
