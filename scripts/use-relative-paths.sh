#!/usr/bin/env bash

# This script changes the paths in the docker-compose.yml file to use relative paths
# Previously, we were using ${PWD} to get the path to the current directory, but this
# caused issues when running a script from a different directory with "docker-compose -f".

config()
{
  echo "Checking docker-compose file... "
    FABMANAGER_PATH=$(pwd)
    if [ ! -w "$FABMANAGER_PATH/docker-compose.yml" ]; then
      echo "Fab-manager's docker-compose.yml file not found or not writable."
      echo "Please run this script from the installation folder, and as a user having write access on docker-compose.yml"
      exit 1
    fi
}

rename()
{
  echo "Renaming paths... "
  sed -i.bak "s/\${PWD}/\./g" "$FABMANAGER_PATH/docker-compose.yml"
}

proceed()
{
  config
  rename
}

proceed "$@"
