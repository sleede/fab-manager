#!/usr/bin/env bash

yq() {
  docker run --rm -i -v "${PWD}:/workdir" mikefarah/yq:4 "$@"
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

set_user()
{
  CURRENT_VALUE=$(yq eval ".services.$SERVICE.user" docker-compose.yml)
  USER_ID="$(id -u):$(id -g)"
  if [[ "$CURRENT_VALUE" == "USER_ID" || "$CURRENT_VALUE" == "null" ]]; then
    yq -i eval ".services.$SERVICE.user |= \"$USER_ID\"" docker-compose.yml
    echo "Service user was set to $USER_ID for $SERVICE"
  fi
}

proceed()
{
  config
  set_user
}

proceed "$@"
