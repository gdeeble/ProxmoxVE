#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/gdeeble/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 Gary Deeble
# Author: Gary Deeble (gdeeble)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/openspeedtest/Speed-Test
# Source: https://github.com/openspeedtest/Nginx-Configuration/

# App Default Values
APP="OpenSpeedtest"
var_tags="speedtest"
var_cpu="2"
var_ram="512"
var_disk="1"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/openspeedtest ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Stopping ${APP}"
  systemctl stop nginx
  msg_ok "Stopped ${APP}"

  msg_info "Updating ${APP}"
  cd /opt/openspeedtest
  output=$(git pull --no-rebase)
  if echo "$output" | grep -q "Already up to date."; then
    msg_ok "$APP is already up to date."
    exit
  fi
  msg_ok "Updated Successfully"

  msg_info "Starting ${APP}"
  systemctl restart nginx
  msg_ok "Started ${APP}"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"