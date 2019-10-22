#!/usr/bin/env bash

config()
{
  if [ "$(whoami)" = "root" ]
  then
    echo "It is not recommended to run this script as root. As a normal user, elevation will be prompted if needed."
    read -rp "Continue anyway? (Y/n) " confirm </dev/tty
    if [[ "$confirm" = "n" ]]; then exit 1; fi
  else
    if ! command -v sudo
    then
      echo "Please install and configure sudo before running this script."
      echo "sudo was not found, exiting..."
      exit 1
    elif ! groups | grep sudo; then
      echo "Please add your current user to the sudoers."
      echo "You can run the following as root: \"usermod -aG sudo $(whoami)\", then logout and login again"
      echo "sudo was not configured, exiting..."
      exit 1
    fi
    if ! groups | grep docker; then
      echo "Please add your current user to the docker group."
      echo "You can run the following as root: \"usermod -aG docker $(whoami)\", then logout and login again"
      echo "current user is not allowed to use docker, exiting..."
      exit 1
    fi
  fi
  if ! command -v awk || ! [[ $(awk -W version) =~ ^GNU ]]
  then
    echo "Please install GNU Awk before running this script."
    echo "gawk was not found, exiting..."
    exit 1
  fi
  FM_PATH=$(pwd)
  TYPE="NOT-FOUND"
  read -rp "Is fab-manager installed at \"$FM_PATH\"? (y/N) " confirm </dev/tty
  if [ "$confirm" = "y" ]; then
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

test_free_space()
{
  # checking disk space (minimum required = 1.2GB)
  required=$(du -d 0 "$PG_PATH" | awk '{ print $1 }')
  space=$(df "$FM_PATH" | awk '/[0-9]%/{print $(NF-2)}')
  if [ "$space" -lt "$required" ]
  then
    echo "Not enough free disk space to perform upgrade. Please free at least $required bytes of disk space and try again"
    df -h "$FM_PATH"
    exit 7
  fi
}

test_docker_compose()
{
  if [[ -f "$FM_PATH/docker-compose.yml" ]]
  then
    if docker-compose ps | grep postgres
    then
      TYPE="DOCKER-COMPOSE"
    fi
  fi
}

read_path()
{
    PG_PATH=$(awk "BEGIN { FS=\"\n\"; RS=\"\"; } { match(\$0, /image: postgres:$OLD(\n|.)+volumes:(\n|.)+(-.*postgresql\/data)/, lines); FS=\"[ :]+\"; RS=\"\r\n\"; split(lines[3], line); print line[2] }" "$FM_PATH/docker-compose.yml")
    PG_PATH="${PG_PATH/\$\{PWD\}/$(pwd)}"
    PG_PATH="${PG_PATH/[[:space:]]/}"
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

docker_down()
{
  docker-compose down
  ensure_pg_down
}

ensure_pg_down()
{
  if [ -f "$PG_PATH/postmaster.pid" ]; then
    echo 'ERROR: lock file "postmaster.pid" exists'
    if ! docker-compose ps | grep postgres; then
      read -rp 'docker-compose container is not running. Confirm delete the lock file? (y/N) ' confirm </dev/tty
      if [ "$confirm" = "y" ]; then
        if [ "$(whoami)" = "root" ]; then COMMAND="rm"
        else COMMAND="sudo rm"; fi
        "$COMMAND" -f "$PG_PATH/postmaster.pid"
      fi
    else
      echo 'docker-compose container is still running, retrying to stop...'
      sleep 2
      docker_down
    fi
  fi
}

pg_upgrade()
{
  docker run --rm \
    -v "$PG_PATH:/var/lib/postgresql/$OLD/data" \
    -v "$NEW_PATH:/var/lib/postgresql/$NEW/data" \
    "tianon/postgres-upgrade:$OLD-to-$NEW"
}


upgrade_compose()
{
  echo -e "\nUpgrading docker-compose installation from $OLD to $NEW..."

  # update image tag and data directory into docker-compose file
  awk "BEGIN { FS=\"\n\"; RS=\"\"; } { print gensub(/(image: postgres:$OLD(\n|.)+volumes:(\n|.)+(-.*postgresql\/data))/, \"image: postgres:$NEW\n    volumes:\n      - ${NEW_PATH}:/var/lib/postgresql/data\", \"g\") }" "$FM_PATH/docker-compose.yml" > "$FM_PATH/.awktmpfile" && mv "$FM_PATH/.awktmpfile" "$FM_PATH/docker-compose.yml"
}

trust_pg_hba_conf()
{
  if [ "$(whoami)" = "root" ]; then COMMAND="tee"
  else COMMAND="sudo tee"; fi
  {
    echo
    echo "host all all all trust"
  } | "$COMMAND" -a "$NEW_PATH/pg_hba.conf" > /dev/null
}

docker_up()
{
  docker-compose pull
  docker-compose up -d
}

clean()
{
  read -rp "Remove the previous PostgreSQL data folder? (y/N) " confirm </dev/tty
  if [[ "$confirm" = "y" ]]
  then
    echo "Deleting $PG_PATH..."
    rm -rf "$PG_PATH"
  fi
}

upgrade_postgres()
{
  config
  read -rp "Continue with upgrading? (y/N) " confirm </dev/tty
  if [[ "$confirm" = "y" ]]
  then
    OLD='9.4'
    NEW='9.6'
    read_path
    test_free_space
    prepare_path
    docker_down
    pg_upgrade
    upgrade_compose
    trust_pg_hba_conf
    docker_up
    clean
  fi
}

upgrade_postgres "$@"
