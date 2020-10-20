#!/usr/bin/env bash

yq() {
  docker run --rm -i -v "${PWD}:/workdir" mikefarah/yq yq "$@"
}

config()
{
  echo -ne "Checking user... "
  if [[ "$(whoami)" != "root" ]] && ! groups | grep docker
  then
      echo "Please add your current user to the docker group OR run this script as root."
      echo "current user is not allowed to use docker, exiting..."
      exit 1
  fi
  if ! command -v awk || ! [[ $(awk -W version) =~ ^GNU ]]
  then
    echo "Please install GNU Awk before running this script."
    echo "gawk was not found, exiting..."
    exit 1
  fi
  SERVICE="$(yq r docker-compose.yml --printMode p 'services.*(.==sleede/fab-manager*)' | awk 'BEGIN { FS = "." } ; {print $2}')"
}

change_mount()
{
  local volumes=$(yq r docker-compose.yml --length "services.$SERVICE.volumes")
  local maxVol=$(($volumes - 1))
  for i in $(seq 0 $maxVol); do
    yq r docker-compose.yml "services.$SERVICE.volumes.[$i]" | grep assets
    if [[ $? = 0 ]]; then
      yq w docker-compose.yml "services.$SERVICE.volumes.[$i]" "\${PWD}/public/packs:/usr/src/app/public/packs"
      echo "Volume #$i was replaced for $SERVICE: /assets changed to /packs"
      exit 0
    fi
  done
}

proceed()
{
  config
  change_mount
}

proceed "$@"
