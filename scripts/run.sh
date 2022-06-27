#!/usr/bin/env bash

yq() {
  docker run --rm -i -v "${PWD}:/workdir" --user "$UID" mikefarah/yq:4 "$@"
}

config() {
  SERVICE="$(yq eval '.services.*.image | select(. == "sleede/fab-manager*") | path | .[-2]' docker-compose.yml)"
}

docker-compose()
{
  if ! docker compose version 1>/dev/null 2>/dev/null
  then
    if ! command docker-compose version 1>/dev/null 2>/dev/null
    then
      echo -e "\e[91m[ ❌ ] docker-compose was not found, exiting...\e[39m" && exit 1
    else
      command docker-compose "$@"
    fi
  else
    docker compose "$@"
  fi
}

run()
{
  config
  docker-compose exec "$SERVICE" bundle exec rails "${@:-c}" </dev/tty
}

run "$@"
