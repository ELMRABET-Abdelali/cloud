#!/bin/bash

# Exit on error
set -e

# Update and upgrade system
apt update && apt upgrade -y

# Remove netfilter and reboot (commented out to avoid stopping the script)
apt remove netfilter-persistent -y
# reboot # Uncomment this line if you want to reboot here manually.

# Install vsftpd
apt install vsftpd -y
systemctl start vsftpd

# Create FTP user
useradd -m ftpuser
echo "ftpuser:FTPuser25" | chpasswd  # Default password is set to FTPuser25

# Backup the original vsftpd.conf
cp /etc/vsftpd.conf /etc/vsftpd.conf.default

# Configure vsftpd with the updated content
EXTERNAL_IP=$(curl -s ifconfig.me)

cat <<EOL > /etc/vsftpd.conf
# Example config file /etc/vsftpd.conf
#
# Run standalone?  vsftpd can run either from an inetd or as a standalone
# daemon started from an initscript.
listen=yes

# Allow anonymous FTP? (Disabled by default).
anonymous_enable=NO

# Uncomment this to allow local users to log in.
local_enable=YES

# Uncomment this to enable any form of FTP write command.
write_enable=YES

# Activate directory messages
dirmessage_enable=YES

# Use local time
use_localtime=YES

# Activate logging of uploads/downloads.
xferlog_enable=YES

# Make sure PORT transfer connections originate from port 20 (ftp-data).
connect_from_port_20=YES

# Secure chroot directory
secure_chroot_dir=/var/run/vsftpd/empty

# SSL configuration
rsa_cert_file=/etc/ssl/private/vsftpd.pem
rsa_private_key_file=/etc/ssl/private/vsftpd.pem
ssl_enable=YES
allow_anon_ssl=NO
force_local_data_ssl=YES
force_local_logins_ssl=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
require_ssl_reuse=NO
ssl_ciphers=HIGH
utf8_filesystem=YES

# Passive mode configuration
pasv_enable=YES
pasv_min_port=50000
pasv_max_port=60000
pasv_address=$EXTERNAL_IP
port_enable=YES
EOL

# Restart vsftpd to apply changes
systemctl restart vsftpd

# Install and configure UFW
apt install ufw -y
ufw allow ssh
ufw allow ftp
ufw allow 50000:60000/tcp
ufw --force enable  # Enable without interactive confirmation

# Configure SSL for vsftpd
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/vsftpd.pem -out /etc/ssl/private/vsftpd.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=IT/CN=ftpserver"

# Add FTP user to vsftpd user list
echo "ftpuser" | tee -a /etc/vsftpd.userlist

# Restart vsftpd to apply final changes
systemctl restart vsftpd

# Output completion message
echo "FTP server setup complete. Please follow these steps:"
echo " - Default FTP user: ftpuser"
echo " - Default FTP password: FTPuser25"
echo " - Host: $EXTERNAL_IP"
echo " - Port: 21"
echo " - Passive Mode Ports: 50000-60000"
echo " - Encryption: Plain FTP or TLS as configured"
echo " - Transfer Settings: Passive or fallback to active mode if passive fails"
echo " - IMPORTANT: Please reboot the server before testing the configuration."
