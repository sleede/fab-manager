#!/usr/bin/env bash

# 3 options:
# - docker compose
# - docker "simple"
# - classic installation
#   > macOS
#   > ubuntu
#   > debian


config()
{
  FM_PATH=$(pwd)
  read -rp "Is fab-manager installed at \"$FM_PATH\"? (y/n)" confirm </dev/tty
  if [ "$confirm" = "y" ]
  then
    ES_HOST=$(cat "$FM_PATH/config/application.yml" | grep ELASTICSEARCH_HOST | awk '{print $2}')
    ES_IP=$(getent hosts "$ES_HOST" | awk '{ print $1 }')
  else
    echo "Please run this script from the fab-manager's installation folder"
    exit 1
  fi
}

test_docker_compose()
{
  ls "$FM_PATH/docker-compose.yml"
  if [[ $? = 0 ]]
  then
    docker-compose ps | grep elastic
    if [[ $? = 0 ]]; then echo "DOCKER-COMPOSE"; fi
  fi
}

test_docker()
{
  docker ps | grep elasticsearch:1.7
  if [[ $? = 0 ]]
  then
    local containers=$(docker ps | grep elasticsearch:1.7)
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(echo "$containers" | awk '{print $1}') | grep "$ES_IP"
    if [[ $? = 0 ]]; then echo "DOCKER"; fi
  fi
}

test_classic()
{
  if [[ "$ES_IP" = "127.0.0.1" || "$ES_IP" = "::1" ]]
  then
    whereis -b elasticsearch | grep "/"
    if [[ $? = 0 ]]; then echo "CLASSIC"; fi
  fi
}

test_running()
{
  local http_res=$(curl -I "$ES_HOST:9200" 2>/dev/null | head -n 1 | cut -d$' ' -f2)
  if [ "$http_res" -eq 200 ]
  then
    echo "ONLINE"
  else
    echo "OFFLINE"
  fi
}

detect_installation()
{
  echo "Detecting installation type..."

  TYPE="NOT-FOUND"
  local compose=$(test_docker_compose)
  if [[ "$compose" = "DOCKER-COMPOSE" ]]
  then
    echo "Docker-compose installation detected."
    TYPE="DOCKER-COMPOSE"
  else
    local docker=$(test_docker)
    if [[ "$docker" = "DOCKER-COMPOSE" ]]
    then
    echo "Classical docker installation detected."
      TYPE="DOCKER"
    else
      local classic=$(test_classic)
      if [[ "$classic" = "CLASSIC" ]]
      then
        echo "Local installation detected on the host system."
        TYPE="CLASSIC"
      fi
    fi
  fi

  if [[ "$TYPE" = "NOT-FOUND" ]]
  then
    echo "ElasticSearch 1.7 was not found on the current system, exiting..."
    exit 2
  else
    echo "Detecting online status..."
    if [[ "$TYPE" != "NOT-FOUND" ]]
    then
        STATUS=$(test_running)
    fi
  fi
}

upgrade_compose()
{
  echo "Upgrading docker-compose installation..."
  docker-compose stop elasticsearch
  docker-compose rm -f elasticsearch
  sed -i.bak s/image: elasticsearch:1.7/image: elasticsearch:2.4/g "$FM_PATH/docker-compose.yml"
  docker-compose pull
  docker-compose up -d
  sleep 10
  STATUS=$(test_running)
  if [[ "$STATUS" = "ONLINE" ]]; then
    echo "Migration to elastic 2.4 was successful."
  else
    echo "Unable to find an active ElasticSearch instance, something may have went wrong, exiting..."
    exit 4
  fi
}

upgrade_docker()
{
  echo "Upgrading docker installation..."
  local containers=$(docker ps | grep elasticsearch:1.7)
  # get container id
  local id=$(docker inspect -f '{{.Id}} {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(echo "$containers" | awk '{print $1}') | grep "$ES_IP" | awk '{print $1}')
  # get container name
  local name=$(docker inspect -f '{{.Name}}' "$id" | sed s:^/::g)
  # get container network name
  local network=$(docker inspect -f '{{.NetworkSettings.Networks}}' "$id" | sed)
  # get container mapping to data folder
  docker pull elasticsearch:2.4
  docker run --restart=always  -d --name=fabmanager-elastic -v /home/core/fabmanager/elasticsearch:/usr/share/elasticsearch/data elasticsearch:2.4

}


upgrade_classic()
{
  echo "Automated upgrade of local installation is not supported."
  echo "Please refer to your distribution instructions to install ElasticSearch 2.4"
  echo "For more informations: https://www.elastic.co/guide/en/elasticsearch/reference/2.0/setup-upgrade.html"
}

start_upgrade()
{
  case "$TYPE" in
  "DOCKER-COMPOSE")
    upgrade_compose
    ;;
  "DOCKER")
    upgrade_docker
    ;;
  "CLASSIC")
    upgrade_classic
    ;;
  *)
    echo "Unexpected ElasticSearch installation $TYPE"
    exit 3
  esac
}

upgrade_elastic()
{
  config
  detect_installation
  start_upgrade
}

upgrade_elastic "$@"