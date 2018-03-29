#!/usr/bin/env bash

# 3 options:
# - docker compose
# - docker "simple"
# - classic installation
#   > macOS
#   > debian/ubuntu
#   > other linux


config()
{
  FM_PATH=$(pwd)
  TYPE="NOT-FOUND"
  read -rp "Is fab-manager installed at \"$FM_PATH\"? (y/n) " confirm </dev/tty
  if [ "$confirm" = "y" ]
  then
    if [ -f "$FM_PATH/config/application.yml" ]
    then
      ES_HOST=$(cat "$FM_PATH/config/application.yml" | grep ELASTICSEARCH_HOST | awk '{print $2}')
    elif [ -f "$FM_PATH/config/env" ]
    then
      ES_HOST=$(cat "$FM_PATH/config/env" | grep ELASTICSEARCH_HOST | awk '{split($0,a,"="); print a[2]}')
    fi
    ES_IP=$(getent hosts "$ES_HOST" | awk '{ print $1 }')
  else
    echo "Please run this script from the fab-manager's installation folder"
    exit 1
  fi
}

test_docker_compose()
{
  if [[ -f "$FM_PATH/docker-compose.yml" ]]
  then
    docker-compose ps | grep elastic
    if [[ $? = 0 ]]
    then
      TYPE="DOCKER-COMPOSE"
      local container_id=$(docker-compose ps | grep elastic | awk '{print $1}')
      ES_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_id")
    fi
  fi
}

test_docker()
{
  docker ps | grep elasticsearch:1.7
  if [[ $? = 0 ]]
  then
    local containers=$(docker ps | grep elasticsearch:1.7)
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(echo "$containers" | awk '{print $1}') | grep "$ES_IP"
    if [[ $? = 0 ]]; then TYPE="DOCKER"; fi
  fi
}

test_classic()
{
  if [ "$ES_IP" = "127.0.0.1" ] || [ "$ES_IP" = "::1" ]
  then
    whereis -b elasticsearch | grep "/"
    if [[ $? = 0 ]]; then TYPE="CLASSIC"; fi
  fi
}

test_running()
{
  local http_res=$(curl -I "$ES_IP:9200" 2>/dev/null | head -n 1 | cut -d$' ' -f2)
  if [ "$http_res" = "200" ]
  then
    echo "ONLINE"
  else
    echo "OFFLINE"
  fi
}

test_version()
{
  local version=$(curl "$ES_IP:9200"  2>/dev/null | grep number | awk '{print $3}')
  if [[ "$version" = *\"1.7* ]]; then echo "1.7"
  elif [[ "$version" = *\"2.4* ]]; then echo "2.4"
  fi
}

detect_installation()
{
  echo "Detecting installation type..."

  test_docker_compose
  if [[ "$TYPE" = "DOCKER-COMPOSE" ]]
  then
    echo "Docker-compose installation detected."
  else
    test_docker
    if [[ "$TYPE" = "DOCKER" ]]
    then
    echo "Classical docker installation detected."
    else
      test_classic
      if [[ "$TYPE" = "CLASSIC" ]]
      then
        echo "Local installation detected on the host system."
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
  sed -i.bak 's/image: elasticsearch:1.7/image: elasticsearch:2.4/g' "$FM_PATH/docker-compose.yml"
  docker-compose pull
  docker-compose up -d
  sleep 10
  STATUS=$(test_running)
  local version=$(test_version)
  if [ "$STATUS" = "ONLINE" ] && [ "$version" = "2.4" ]; then
    echo "Migration to elastic 2.4 was successful."
  else
    echo "Unable to find an active ElasticSearch 2.4 instance, something may have went wrong, exiting..."
    echo "status: $STATUS, version: $version"
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
  local network=$(docker inspect -f '{{.NetworkSettings.Networks}}' "$id" | sed 's/map\[\(.*\):0x[a-f0-9]*\]/\1/')
  # get container mapping to data folder
  local mounts=$(docker inspect -f '{{.Mounts}}' "$id" | sed 's/} {/\n/g' | sed 's/^\[\?{\?bind[[:blank:]]*\([^[:blank:]]*\)[[:blank:]]*\([^[:blank:]]*\)[[:blank:]]*true \(rprivate\)\?}\?]\?$/-v \1:\2/g' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g')
  # stop elastic 1.7
  docker stop "$name"
  docker rm -f "$name"
  # run elastic 2.4
  docker pull elasticsearch:2.4
  echo docker run --restart=always  -d --name="$name" --network="$network" --ip="$ES_IP" "$mounts" elasticsearch:2.4 | bash
  # check status
  sleep 10
  STATUS=$(test_running)
  local version=$(test_version)
  if [ "$STATUS" = "ONLINE" ] && [ "$version" = "2.4" ]; then
    echo "Migration to elastic 2.4 was successful."
  else
    echo "Unable to find an active ElasticSearch 2.4 instance, something may have went wrong, exiting..."
    echo "status: $STATUS, version: $version"
    exit 4
  fi
}


upgrade_classic()
{
  local system=$(uname -s)
  case "$system" in
    Linux*)
      if [ -f /etc/os-release ]
      then
        . /etc/os-release
        if [ "$ID" = 'debian' ] || [[ "$ID_LIKE" = *'debian'* ]]
        then
          # Debian compatible
          wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
          echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list
          sudo apt-get update && sudo apt-get upgrade
        fi
      fi
      ;;
    Darwin*)
      echo "OS X"
      brew update
      brew install homebrew/versions/elasticsearch24
      ;;
    *)
      echo "Automated upgrade of your elasticSearch installation is not supported on your system."
      echo "Please refer to your distribution instructions to install ElasticSearch 2.4"
      echo "For more informations: https://www.elastic.co/guide/en/elasticsearch/reference/2.0/setup-upgrade.html"
      ;;
  esac
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