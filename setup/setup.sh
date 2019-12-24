#!/bin/bash

prepare_config()
{
  FABMANAGER_PATH=${1:-/apps/fabmanager}

  mkdir -p "$FABMANAGER_PATH/config/nginx/ssl"
  mkdir -p "$FABMANAGER_PATH/letsencrypt/config"
  mkdir -p "$FABMANAGER_PATH/letsencrypt/etc/webrootauth"
  mkdir -p "$FABMANAGER_PATH/elasticsearch/config"

  # fab-manager environment variables
  \curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/setup/env.example > "$FABMANAGER_PATH/config/env"

  # nginx configuration
  \curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/setup/nginx_with_ssl.conf.example > "$FABMANAGER_PATH/config/nginx/fabmanager.conf.ssl"
  \curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/setup/nginx.conf.example > "$FABMANAGER_PATH/config/nginx/fabmanager.conf"

  # let's encrypt configuration
  \curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/setup/webroot.ini.example > "$FABMANAGER_PATH/letsencrypt/config/webroot.ini"

  # ElasticSearch configuration files
  \curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/setup/elasticsearch.yml > "$FABMANAGER_PATH/elasticsearch/config/elasticsearch.yml"
  \curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/setup/log4j2.properties > "$FABMANAGER_PATH/elasticsearch/config/log4j2.properties"

  # docker-compose
  \curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/setup/docker-compose.yml > "$FABMANAGER_PATH/docker-compose.yml"
}

function trap_ctrlc()
{
  echo "Ctrl^C, exiting..."
  exit 2
}

trap "trap_ctrlc" 2 # SIGINT
prepare_config "$@"
