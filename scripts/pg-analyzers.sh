#!/usr/bin/env bash

docker-compose()
{
  if ! docker compose version 1>/dev/null 2>/dev/null
  then
    if ! \docker-compose version 1>/dev/null 2>/dev/null
    then
      echo -e "\e[91m[ ❌ ] docker-compose was not found, exiting...\e[39m" && exit 1
    else
      \docker-compose "$@"
    fi
  else
    docker compose "$@"
  fi
}

docker-compose exec -T postgres psql -Upostgres -c \\dFd | head -n -2 | tail -n +3 | awk '{ print gensub(/([a-z]+)_stem/,"\\1","g",$3); }'
