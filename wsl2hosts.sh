#!/bin/bash
# --------------------------------------------------------------------------------------------------
# Name:        .wsl2hosts.sh
# Version:     1.0.0
# Date:        2023-02-21
# Author:      berndgz inspired by https://github.com/iamqiz/bash-wsl2-host
# Description: bash script to automatically update your Windows hosts file with the WSL2 VM IP addr.
# Requirement: WSL2, WindowsPowerShell, https://github.com/gerardog/gsudo, elevated privileges.
# Note:        gsudo is a sudo equivalent for Windows, with a similar user-experience.
# Usage:       add location from gsudo and WindowsPowerShell to PATH environment variable.
#              add this script to ~/.bashrc and define your dns name in '_wsl_ssh_ip_name' variable.
# --------------------------------------------------------------------------------------------------

# adjust this paths to your environment
GSUDO_EXEC=/mnt/c/tools/gsudo/current/gsudo
PS_EXEC=/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe

change_wsl_ssh_ip(){
  # define your dns name
  _wsl_ssh_ip_name="ubuntu2004.wsl"

  # set windows hosts file path
  _wslhosts=/mnt/c/Windows/System32/drivers/etc/hosts
  _winhosts='C:\Windows\System32\drivers\etc\hosts'

  # get wsl real ip and ignore wsl-vpnkit
  _wsl_ssh_ip_addr=$(ip -4 addr show "eth0" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
  echo "wsl ssh ip addr:[$_wsl_ssh_ip_addr]"

  # get current ip from windows hosts
  _win_ssh_ip_addr=$(grep -oP "\d+(\.\d+){3}(?=\s*$_wsl_ssh_ip_name)" $_wslhosts)
  echo "win ssh ip addr:[$_win_ssh_ip_addr]"

  # check if ip exists or diff, then modify
  if [[ "$_win_ssh_ip_addr" == "" ]]
  then
    echo "ssh ip is missing, adding to windows hosts"
    $GSUDO_EXEC $PS_EXEC -Command "echo '' '$_wsl_ssh_ip_addr  $_wsl_ssh_ip_name' | out-file -encoding ASCII $_winhosts -append"
  else
    if [[ "$_win_ssh_ip_addr" != "$_wsl_ssh_ip_addr" ]]
    then
      echo "ssh ip diff, modifying windows hosts"
      $GSUDO_EXEC $PS_EXEC -Command "(gc $_winhosts) -replace '$_win_ssh_ip_addr', '$_wsl_ssh_ip_addr' | out-file -encoding ASCII $_winhosts"
    else
      echo "ssh ip ok"
    fi
  fi

  # resulting windows hosts
  echo "now $_wsl_ssh_ip_name 's ip is:"
  grep "$_wsl_ssh_ip_name" $_wslhosts
}

# run the function
change_wsl_ssh_ip
