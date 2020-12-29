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

add_mount()
{
  # shellcheck disable=SC2016
  # we don't want to expand ${PWD}
  yq w docker-compose.yml "services.$SERVICE.volumes[+]" '- ${PWD}/payment_schedules:/usr/src/app/payment_schedules'
}

proceed()
{
  config
  add_mount
}

proceed "$@"
