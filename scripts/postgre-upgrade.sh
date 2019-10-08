#!/usr/bin/env bash

config()
{
  if [ "$(whoami)" = "root" ]
  then
    echo "It is not recommended to run this script as root. As a normal user, elevation will be prompted if needed."
    read -rp "Continue anyway? (y/n) " confirm </dev/tty
    if [[ "$confirm" = "n" ]]; then exit 1; fi
  fi

  FM_PATH=$(pwd)
  TYPE="NOT-FOUND"
  read -rp "Is fab-manager installed at \"$FM_PATH\"? (y/n) " confirm </dev/tty
  if [ "$confirm" = "y" ]
  then
    # checking disk space (minimum required = 1168323KB)
    space=$(df $FM_PATH | awk '/[0-9]%/{print $(NF-2)}')
    if [ "$space" -lt 1258291 ]
    then
      echo "Not enough free disk space to perform upgrade. Please free at least 1,2GB of disk space and try again"
      df -h $FM_PATH
      exit 7
    fi
    if [ -f "$FM_PATH/config/application.yml" ]
    then
      PG_HOST=$(cat "$FM_PATH/config/application.yml" | grep POSTGRES_HOST | awk '{print $2}')
    elif [ -f "$FM_PATH/config/env" ]
    then
      PG_HOST=$(cat "$FM_PATH/config/env" | grep POSTGRES_HOST | awk '{split($0,a,"="); print a[2]}')
    else
      echo "Fab-manager's environment file not found, please run this script from the installation folder"
      exit 1
    fi
    PG_IP=$(getent ahostsv4 "$PG_HOST" | awk '{ print $1 }' | uniq)
    test_docker_compose
    if [[ "$TYPE" = "NOT-FOUND" ]]
    then
      echo "PostgreSQL was not found on the current system, exiting..."
      exit 2
    fi
  else
    echo "Please run this script from the fab-manager's installation folder"
    exit 1
  fi
}

test_docker_compose()
{
  if [[ -f "$FM_PATH/docker-compose.yml" ]]
  then
    docker-compose ps | grep postgres
    if [[ $? = 0 ]]
    then
      TYPE="DOCKER-COMPOSE"
      local container_id=$(docker-compose ps | grep postgre | awk '{print $1}')
      PG_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_id")
    fi
  fi
}

read_path()
{
    PG_PATH=$(awk "BEGIN { FS=\"\n\"; RS=\"\"; } { match(\$0, /image: postgres:$NEW(\n|.)+volumes:(\n|.)+(-.*postgresql\/data)/, lines); FS=\"[ :]+\"; RS=\"\r\n\"; split(lines[3], line); print line[2] }" "$FM_PATH/docker-compose.yml")
}

prepare_path()
{
  if ! ls "$PG_PATH/base" 2>/dev/null
  then
    echo "PostgreSQL does not seems to be installed in $PG_PATH"
    read -rep "Please specify the PostgreSQL data folder: " PG_PATH </dev/tty
    prepare_path
  else
    NEW_PATH="$PG_PATH-$NEW"
    mkdir -p "$NEW_PATH"
  fi
}

pg_upgrade()
{
  docker run --rm \
    -v "$PG_PATH:/var/lib/postgresql/$OLD/data" \
    -v "$PG_PATH-$NEW:/var/lib/postgresql/$NEW/data" \
    "tianon/postgres-upgrade:$OLD-to-$NEW" --link

}


upgrade_compose()
{
  echo -e "\nUpgrading docker-compose installation from $OLD to $NEW..."
  docker-compose stop postgres
  docker-compose rm -f postgres
  local image="postgres:$NEW"
  sed -i.bak "s/image: postgres:$OLD/image: $NEW/g" "$FM_PATH/docker-compose.yml"

  # insert configuration directory into docker-compose bindings
  awk "BEGIN { FS=\"\n\"; RS=\"\"; } { print gensub(/(image: postgres:$NEW(\n|.)+volumes:(\n|.)+(-.*postgresql\/data))/, \"\\\\1\n      - ${NEW_PATH}:/var/lib/postgresql/data\", \"g\") }" "$FM_PATH/docker-compose.yml" > "$FM_PATH/.awktmpfile" && mv "$FM_PATH/.awktmpfile" "$FM_PATH/docker-compose.yml"

  docker-compose pull
  docker-compose up -d
}

upgrade_elastic()
{
  config
  read -rp "Continue with upgrading? (y/n) " confirm </dev/tty
  if [[ "$confirm" = "y" ]]
  then
    OLD='9.4'
    NEW='11'
    read_path
    prepare_path
    pg_upgrade
    upgrade_compose
  fi
}

upgrade_elastic "$@"
