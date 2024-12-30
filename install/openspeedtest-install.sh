#!/usr/bin/env bash

# Copyright (c) 2021-2024 Gary Deeble
# Author: Gary Deeble (gdeeble)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/openspeedtest/Speed-Test
# Source: https://github.com/openspeedtest/Nginx-Configuration/

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get update
$STD apt-get install -y \
  gpg \
  curl \
  sudo \
  git \
  nginx

msg_ok "Installed Dependencies"

msg_info "Installing Open Speed Test"

# Get the latest version of the speed test
$STD git clone https://github.com/openspeedtest/Speed-Test.git /opt/openspeedtest/

# Clean up permissions and link it to nginx's default web-root
$STD chmod -R 755 /opt/openspeedtest/
rm -rf /usr/share/nginx/html/
mkdir -p /usr/share/nginx
ln -s  /opt/openspeedtest/ /usr/share/nginx/html

# Get a preconfigured nginx configuration from the dev team
$STD wget -q --content-disposition https://raw.githubusercontent.com/openspeedtest/Nginx-Configuration/refs/heads/main/nginx.conf 

# Configure nginx pid config to use the /run directory
sed -i 's|pid\s\+/tmp/nginx.pid;|pid        /run/nginx.pid;|' nginx.conf

# Move the updated file to nginx config directory
mv nginx.conf /etc/nginx/nginx.conf

# Get a preconfigured copy of the nginx site configuration
$STD wget -q --content-disposition https://raw.githubusercontent.com/openspeedtest/Nginx-Configuration/refs/heads/main/OpenSpeedTest-Server.conf 

# Disable SSL from the nginx Config
sed -i -e '/listen 3001 ssl reuseport;/s/^/#/' \
       -e '/listen \[::\]:3001 ssl reuseport;/s/^/#/' \
       -e '/ssl_certificate \/etc\/ssl\/nginx.crt;/s/^/#/' \
       -e '/ssl_certificate_key \/etc\/ssl\/nginx.key;/s/^/#/' \
       -e '/ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;/s/^/#/' \
       -e '/ssl_ciphers "ALL";/s/^/#/' \
       -e '/ssl_prefer_server_ciphers on;/s/^/#/' \
       -e '/ssl_session_cache shared:SSL:100m;/s/^/#/' \
       -e '/ssl_session_timeout 1d;/s/^/#/' \
       -e '/ssl_session_tickets on;/s/^/#/' OpenSpeedTest-Server.conf 
# Move the updated file to nginx config directory
mv OpenSpeedTest-Server.conf /etc/nginx/conf.d/OpenSpeedTest-Server.conf 

RELEASE=$(curl -s https://github.com/openspeedtest/Speed-Test/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
echo "${RELEASE}" >"/opt/${APP}_version.txt"

msg_ok "Installed Open Speed Test"

msg_info "Starting nginx Service"
systemctl enable --now -q nginx
systemctl restart -q nginx
msg_ok "Service Started"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"