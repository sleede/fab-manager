#!/usr/bin/env bash

yq() {
  docker run --rm -i -v "${PWD}:/workdir" --user "$UID" mikefarah/yq:4 "$@"
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
  SERVICE="$(yq eval '.services.*.image | select(. == "sleede/fab-manager*") | path | .[-2]' docker-compose.yml)"
  echo -e "\n"
}

add_mount()
{
  if [[ ! $(yq eval ".services.$SERVICE.volumes.[] | select (. == \"*auth_provider.yml\")" docker-compose.yml) ]]; then
    touch ./config/auth_provider.yml
    # change docker-compose.yml permissions for fix yq can't modify file issue
    chmod 666 docker-compose.yml
    yq -i eval ".services.$SERVICE.volumes += [\"./config/auth_provider.yml:/usr/src/app/config/auth_provider.yml\"]" docker-compose.yml
    chmod 644 docker-compose.yml
  fi
}

proceed()
{
  config
  add_mount
}

proceed "$@"
