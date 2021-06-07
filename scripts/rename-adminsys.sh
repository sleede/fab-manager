#!/usr/bin/env bash

config()
{
  echo -ne "Checking env file... "
  FABMANAGER_PATH=$(pwd)
  if [ ! -w "$FABMANAGER_PATH/config/env" ]; then
    echo "Fab-manager's environment file not found or not writable."
    echo "Please run this script from the installation folder, and as a user having write access on config/env"
    exit 1
  fi
  local _commands=("sed" "grep")
  for _command in "${_commands[@]}"; do
    echo "detecting $_command..."
    if ! command -v "$_command"
    then
      echo "Please install $_command before running this script."
      echo -e "\e[91m[ ❌ ] $_command was not found, exiting...\e[39m" && exit 1
    fi
  done
}

rename_var()
{
  current=$(grep -Po "SUPERADMIN_EMAIL=\K.*" "$FABMANAGER_PATH/config/env")
  sed -i.bak "s/SUPERADMIN_EMAIL=$current/ADMINSYS_EMAIL=$current/g" "$FABMANAGER_PATH/config/env"
}

proceed()
{
  config
  rename_var
}

proceed "$@"
