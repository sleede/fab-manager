#!/bin/bash

prepare_config()
{
  FABMANAGER_PATH=${1:-/apps/fabmanager}

  mkdir -p "$FABMANAGER_PATH/example"

  # fab-manager environment variables
  \curl -sSL https://raw.githubusercontent.com/LaCasemate/fab-manager/master/docker/env.example > "$FABMANAGER_PATH/example/env.example"

  # nginx configuration
  \curl -sSL https://raw.githubusercontent.com/LaCasemate/fab-manager/master/docker/nginx_with_ssl.conf.example > "$FABMANAGER_PATH/example/nginx_with_ssl.conf.example"
  \curl -sSL https://raw.githubusercontent.com/LaCasemate/fab-manager/master/docker/nginx.conf.example > "$FABMANAGER_PATH/example/nginx.conf.example"

  # let's encrypt configuration
  \curl -sSL https://raw.githubusercontent.com/LaCasemate/fab-manager/master/docker/webroot.ini.example > "$FABMANAGER_PATH/example/webroot.ini.example"

  # docker-compose
  \curl -sSL https://raw.githubusercontent.com/LaCasemate/fab-manager/master/docker/docker-compose.yml > "$FABMANAGER_PATH/docker-compose.yml"
}

prepare_config "$@"
