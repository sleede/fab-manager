#!/usr/bin/env bash

parseparams()
{
  COMMANDS=()
  SCRIPTS=()
  ENVIRONMENTS=()
  while getopts "hys:c:e:" opt; do
    case "${opt}" in
      y)
        Y=true
        ;;
      s)
        SCRIPTS+=("$OPTARG")
        ;;
      c)
        COMMANDS+=("$OPTARG")
        ;;
      e)
        ENVIRONMENTS+=("$OPTARG")
        ;;
      *)
        usage
        ;;
    esac
  done
  shift $((OPTIND-1))
}

yq() {
  docker run --rm -i -v "${PWD}:/workdir" mikefarah/yq yq "$@"
}

config()
{
  echo -ne "Checking dependency... "
  if ! command -v awk || ! [[ $(awk -W version) =~ ^GNU ]]
  then
    echo "Please install GNU Awk before running this script."
    echo "gawk was not found, exiting..."
    exit 1
  fi

  echo -ne "Checking user... "
  if [[ "$(whoami)" != "root" ]] && ! groups | grep docker
  then
      echo "Please add your current user to the docker group OR run this script as root."
      echo "current user is not allowed to use docker, exiting..."
      exit 1
  fi

  SERVICE="$(yq r docker-compose.yml --printMode p 'services.*(.==sleede/fab-manager*)' | awk 'BEGIN { FS = "." } ; {print $2}')"
  YES_ALL=${Y:-false}
  # COMMANDS, SCRIPTS and ENVIRONMENTS are set by parseparams
}

add_environments()
{
  for ENV in "${ENVIRONMENTS[@]}"; do
    if [[ "$ENV" =~ ^[A-Z0-9_]+=.*$ ]]; then
      printf "# added on %s\n%s\n" "$(date +%Y-%m-%d\ %R)" "$ENV" >> "config/env"
    else
      echo "Ignoring invalid option: -e $ENV. Given value is not valid environment variable, please see https://huit.re/environment-doc"
    fi
  done
}

upgrade()
{
  [[ "$YES_ALL" = "true" ]] && confirm="y" || read -rp "Proceed with the upgrade? (Y/n) " confirm </dev/tty
  if [[ "$confirm" == "n" ]]; then exit 2; fi

  docker-compose pull "$SERVICE"
  if [[ $? = 1 ]]; then
    printf "An error occured, detected service name: %s\nExiting...", "$SERVICE"
    exit 1
  fi
  for SCRIPT in "${SCRIPTS[@]}"; do
    if [[ "$YES_ALL" = "true" ]]; then
      \curl -sSL "https://raw.githubusercontent.com/sleede/fab-manager/master/scripts/$SCRIPT.sh" | bash -s -- -y
    else
      \curl -sSL "https://raw.githubusercontent.com/sleede/fab-manager/master/scripts/$SCRIPT.sh" | bash
    fi
  done
  docker-compose down
  docker-compose run --rm "$SERVICE" bundle exec rake db:migrate
  rm -rf public/assets
  docker-compose run --rm "$SERVICE" bundle exec rake assets:precompile
  for COMMAND in "${COMMANDS[@]}"; do
    docker-compose run --rm "$SERVICE" bundle exec "$COMMAND"
  done
  docker-compose up -d
  docker ps
}

clean()
{
  echo "Current disk usage:"
  df -h /
  [[ "$YES_ALL" = "true" ]] && confirm="y" || read -rp "Clean previous docker images? (y/N) " confirm </dev/tty
  if [[ "$confirm" == "y" ]]; then
    /usr/bin/docker image prune -f
  fi
}

usage()
{
  printf "Usage: %s [OPTIONS]
Options:
  -h                 Print this message and quit
  -y                 Answer yes to all questions
  -c <string>        Provides additional upgrade command, run in the context of the app (TODO DEPLOY)
  -s <string>        Executes a remote script (TODO DEPOY)
  -e <string>        Adds the environment variable to config/env\n" "$(basename "$0")" 1>&2
  exit 1
}

function trap_ctrlc()
{
  echo "Ctrl^C, exiting..."
  exit 2
}

proceed()
{
  trap "trap_ctrlc" 2 # SIGINT
  parseparams "$@"
  config
  add_environments
  upgrade
  clean
}

proceed "$@"
