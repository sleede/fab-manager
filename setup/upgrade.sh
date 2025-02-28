#!/usr/bin/env bash

parseparams()
{
  COMMANDS=()
  SCRIPTS=()
  ENVIRONMENTS=()
  PREPROCESSING=()
  SKIP_ASSETS=false
  while getopts "hyit:s:p:c:e:-:" opt; do
    case "${opt}" in
      i)
        IGNORE=true
        ;;
      y)
        Y=true
        ;;
      t)
        TARGET=$OPTARG
        FORCE_TARGET=true
        ;;
      s)
        SCRIPTS+=("$OPTARG")
        ;;
      p)
        PREPROCESSING+=("$OPTARG")
        ;;
      c)
        COMMANDS+=("$OPTARG")
        ;;
      e)
        ENVIRONMENTS+=("$OPTARG")
        ;;
      -)
        case "${OPTARG}" in
          no-compile-assets)
            SKIP_ASSETS=true
            ;;
          *)
            usage
            ;;
        esac
        ;;
      *)
        usage
        ;;
    esac
  done
  shift $((OPTIND-1))
}

yq() {
  docker run --rm -i -v "${PWD}:/workdir" --user "$UID" mikefarah/yq:4 "$@"
}

jq() {
  docker run --rm -i -v "${PWD}:/data" --user "$UID" imega/jq "$@"
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


has_sudo()
{
  local prompt

  prompt=$(sudo -nv 2>&1)
  if [ $? -eq 0 ]; then
    echo "has_sudo__pass_set"
  elif echo $prompt | grep -q '^sudo:'; then
    echo "has_sudo__needs_pass"
  else
    echo "no_sudo"
  fi
}

elevate_cmd()
{
  local cmd=$@

  HAS_SUDO=$(has_sudo)

  case "$HAS_SUDO" in
  has_sudo__pass_set)
    sudo $cmd
    ;;
  has_sudo__needs_pass)
    echo "Please supply sudo password for the following command: sudo $cmd"
    sudo $cmd
    ;;
  *)
    echo "Please supply root password for the following command: su -c \"$cmd\""
    su -c "$cmd"
    ;;
  esac
}


# set $SERVICE and $YES_ALL
config()
{
  echo -e "Checking user... "
  if [[ "$(whoami)" != "root" ]] && ! groups | grep docker
  then
      echo "Please add your current user to the docker group OR run this script as root."
      echo "current user is not allowed to use docker, exiting..."
      exit 1
  fi
  echo -e "Checking installation..."
  if [ ! -f "docker-compose.yml" ]; then
    echo -e "\e[91m[ ❌ ] docker-compose.yml was not found in ${PWD}. Please run this script from the Fab-manager's installation folder. Exiting... \e[39m"
    exit 1
  fi
  echo "Checking docker version..."
  DOCKER_VERSION=$(docker -v | grep -oP "([0-9]{1,}\.)+[0-9]{1,}")
  if verlt "$DOCKER_VERSION" 20.10; then
    echo -e "\e[91m[ ❌ ] The installed docker version ($DOCKER_VERSION) is lower than the minimum required version (20.10). Exiting...\e[39m" && exit 1
  fi

  echo "Checking fabmanager service..."
  SERVICE="$(yq eval '.services.*.image | select(. == "sleede/fab-manager*") | path | .[-2]' docker-compose.yml)"
  YES_ALL=${Y:-false}
  # COMMANDS, SCRIPTS and ENVIRONMENTS are set by parseparams

  if [ -z "${SERVICE}" ]; then
    echo -e "\e[91m[ ❌ ] The service name was not determined. Please check your docker-compose.yml file. Exiting... \e[39m"
    exit 1
  fi
  echo -e "\n"
}

# compare versions utilities
# https://stackoverflow.com/a/4024263/1039377
verlte() {
    [  "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
}
verlt() {
    [ "$1" = "$2" ] && return 1 || verlte "$1" "$2"
}

# set $TAG and $TARGET
target_version()
{
  TAG=$(yq eval ".services.$SERVICE.image" docker-compose.yml | grep -o ':.*')

  if [ -n "$TARGET" ]; then return; fi

  if [[ "$TAG" =~ ^:release-v[\.0-9]+$ ]]; then
    TARGET=$(echo "$TAG" | grep -Eo '[\.0-9]{5}')
  elif [ "$TAG" = ":latest" ] || [ "$TAG" = "" ]; then
    HTTP_CODE=$(curl -I -s -w "%{http_code}\n" -o /dev/null https://hub.fab-manager.com/api/versions/latest)
    if [ "$HTTP_CODE" != 200 ]; then
      printf "\n\n\e[91m[ ❌ ] Unable to retrieve the last version of Fab-manager. Please check your internet connection or restart this script providing the \e[1m-t\e[0m\e[91m option\n\e[39m"
      exit 3
    fi
    TARGET=$(\curl -sSL "https://hub.fab-manager.com/api/versions/latest" | jq -r '.semver')
  else
    TARGET='custom'
  fi
}

version_error()
{
  printf "\n\n\e[91m[ ❌ ] You are running Fab-manager version %s\n\e[39m" "${VERSION:-undetermined}"
  printf "You must upgrade Fab-manager to %s.\nPlease refer to http://update.doc.fab.mn for instructions\n" "$1" 1>&2
  exit 3
}

# set $VERSION
version_check()
{
  VERSION=$(docker-compose exec -T "$SERVICE" cat .fabmanager-version 2>/dev/null)
  if [[ $? = 1 ]]; then
    VERSION=$(docker-compose exec -T "$SERVICE" cat package.json | jq -r '.version')
  fi
  target_version
  if [ "$TARGET" = 'custom' ] || [ "$IGNORE" = "true" ]; then return; fi

  HTTP_CODE=$(curl -I -s -w "%{http_code}\n" -o /dev/null "https://hub.fab-manager.com/api/versions/next_step?version=$VERSION")
  if [ "$HTTP_CODE" != 200 ]; then
    printf "\n\n\e[91m[ ❌ ] Unable to check the next step version. Please check your internet connection or restart this script providing the \e[1m-i\e[0m\e[91m option\n\e[39m"
    exit 3
  fi
  STEP=$(\curl -sSL "https://hub.fab-manager.com/api/versions/next_step?version=$VERSION" | jq -r '.next_step.semver')

  if verlt "$VERSION" "$STEP" && verlt "$STEP" "$TARGET"; then
    version_error "$STEP first"
  fi
}

add_environments()
{
  for ENV in "${ENVIRONMENTS[@]}"; do
    if [[ "$ENV" =~ ^[A-Z0-9_]+=.*$ ]]; then
      local var=$(echo "$ENV" | cut -d '=' -f1)
      grep "$var" ./config/env
      if [[ "$?" = 1 ]]; then
        printf "\e[91m::\e[0m \e[1mInserting variable %s..\e[0m.\n" "$ENV"
        printf "# added on %s\n%s\n" "$(date +%Y-%m-%d\ %R)" "$ENV" >> "config/env"
      else
        printf "\e[93m[ ⚠ ] %s is already defined in config/env, ignoring...\e[39m\n" "$var"
      fi
    else
      printf "\e[93m[ ⚠ ] Ignoring invalid option: -e %s.\e[39m\n Given value is not valid environment variable, please see http://env.doc.fab.mn\n" "$ENV"
    fi
  done
}

clean_env_file()
{
  # docker run --env-file does not support whitespaces in the environment variables so we must clean the file
  sed -ri 's/^([A-Z0-9_]+)\s*=\s*(.*)$/\1=\2/g' ./config/env
}

compile_assets()
{
  if [ "$SKIP_ASSETS" = "true" ]; then
    printf "\e[93m[ ⚠ ] Skipping assets compilation as requested with --no-compile-assets option\e[39m\n"
    return 0
  fi

  IMAGE=$(yq eval '.services.*.image | select(. == "sleede/fab-manager*")' docker-compose.yml)
  mapfile -t COMPOSE_ENVS < <(yq eval ".services.$SERVICE.environment" docker-compose.yml)
  ENV_ARGS=$(for i in "${COMPOSE_ENVS[@]}"; do sed 's/: /=/g;s/^/-e /g' <<< "$i"; done)
  PG_ID=$(docker-compose ps -q postgres)
  if [[ "$PG_ID" = "" ]]; then
    restore_tag
    printf "\e[91m[ ❌ ] PostgreSQL container is not running, unable to compile the assets\e[39m\nExiting..."
    exit 4
  fi
  PG_NET_ID=$(docker inspect "$PG_ID" -f "{{json .NetworkSettings.Networks }}" | jq -r '.[] .NetworkID')
  clean_env_file
  if ! mkdir -p public/new_packs; then
    # if, for any reason, the directory cannot be created, we create it with sudo privileges and changes the ownership to the current user
    elevate_cmd mkdir -p public/new_packs
    elevate_cmd chown "$(id -u):$(id -g)" public/new_packs
  fi
  # shellcheck disable=SC2068
  if ! docker run --user "0:0" --rm --env-file ./config/env ${ENV_ARGS[@]} --link "$PG_ID" --net "$PG_NET_ID" -v "${PWD}/public/new_packs:/usr/src/app/public/packs" "$IMAGE" bundle exec rake assets:precompile; then
    printf "\e[93m[ ⚠ ] Something may have went wrong while compiling the assets, please check the logs above.\e[39m\n"
    [[ "$YES_ALL" = "true" ]] && confirm="y" || read -rp "[91m::[0m [1mIgnore and continue?[0m (Y/n) " confirm </dev/tty
    if [[ "$confirm" = "n" ]]; then restore_tag; echo "Exiting..."; exit 4; fi
  fi
  docker-compose down
  if ! rm -rf public/packs; then
    # sometimes we can't delete the packs folder, because of a permission issue. In that case try with sudo
    elevate_cmd rm -rf public/packs
  fi
  mv public/new_packs public/packs
}

force_version()
{
  if [ "$FORCE_TARGET" != "true" ]; then return; fi

  yq -i eval ".services.$SERVICE.image = \"sleede/fab-manager:release-v$TARGET\"" docker-compose.yml
}

restore_tag()
{
  if [ "$FORCE_TARGET" != "true" ]; then return; fi

  yq -i eval ".services.$SERVICE.image = \"sleede/fab-manager$TAG\"" docker-compose.yml
}

upgrade()
{
  local user_target="$TARGET"
  if [ "$TARGET" = 'custom' ]; then user_target="$TAG"; fi

  [[ "$YES_ALL" = "true" ]] && confirm="y" || read -rp "[91m::[0m [1mProceed with upgrading to version $user_target ?[0m (Y/n) " confirm </dev/tty
  if [[ "$confirm" = "n" ]]; then exit 2; fi

  add_environments
  force_version
  if ! docker-compose pull "$SERVICE"; then
    restore_tag
    printf "\e[91m[ ❌ ] An error occurred, detected service name: %s\e[39m\nExiting..." "$SERVICE"
    exit 4
  fi
  BRANCH='master'
  if yq eval '.services.*.image | select(. == "sleede/fab-manager*")' docker-compose.yml | grep -q ':dev'; then BRANCH='dev'; fi
  for SCRIPT in "${SCRIPTS[@]}"; do
    printf "\e[91m::\e[0m \e[1mRunning script %s from branch %s...\e[0m\n" "$SCRIPT" "$BRANCH"
    if [[ "$YES_ALL" = "true" ]]; then
      \curl -sSL "https://raw.githubusercontent.com/sleede/fab-manager/$BRANCH/scripts/$SCRIPT.sh" | bash -s -- -y
    else
      \curl -sSL "https://raw.githubusercontent.com/sleede/fab-manager/$BRANCH/scripts/$SCRIPT.sh" | bash
    fi
    # shellcheck disable=SC2181
    if [[ $? != 0 ]]; then
      printf "\e[93m[ ⚠ ] Something may have went wrong while running \"%s\", please check the logs above...\e[39m\n" "$SCRIPT"
      [[ "$YES_ALL" = "true" ]] && confirm="y" || read -rp "[91m::[0m [1mIgnore and continue?[0m (Y/n) " confirm </dev/tty
      if [[ "$confirm" = "n" ]]; then restore_tag; exit 4; fi
    fi
  done
  for PRE in "${PREPROCESSING[@]}"; do
    printf "\e[91m::\e[0m \e[1mRunning preprocessing command %s...\e[0m\n" "$PRE"
    if ! docker-compose run --rm "$SERVICE" bundle exec "$PRE" </dev/tty; then
      restore_tag
      printf "\e[91m[ ❌ ] Something went wrong while running \"%s\", please check the logs above.\e[39m\nExiting...\n" "$PRE"
      exit 4
    fi
  done
  compile_assets
  if ! docker-compose run --rm "$SERVICE" bundle exec rake db:migrate </dev/tty; then
    restore_tag
    printf "\e[91m[ ❌ ] Something went wrong while migrating the database, please check the logs above.\e[39m\nExiting...\n"
    exit 4
  fi
  for COMMAND in "${COMMANDS[@]}"; do
    printf "\e[91m::\e[0m \e[1mRunning command %s...\e[0m\n" "$COMMAND"
    if ! docker-compose run --rm "$SERVICE" bundle exec "$COMMAND" </dev/tty; then
      restore_tag
      printf "\e[91m[ ❌ ] Something went wrong while running \"%s\", please check the logs above.\e[39m\nExiting...\n" "$COMMAND"
      exit 4
    fi
  done
  docker-compose up -d
  docker ps
}

clean()
{
  echo -e "\e[91m::\e[0m \e[1mCurrent disk usage:\e[0m"
  df -h /
  [[ "$YES_ALL" = "true" ]] && confirm="y" || read -rp "[91m::[0m [1mClean previous docker images?[0m (y/N) " confirm </dev/tty
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
  -i                 Ignore the target version check
  -t <string>        Force the upgrade to target the specified version
  -p <string>        Run the preprocessing command (TODO DEPLOY)
  -c <string>        Provides additional upgrade command, run in the context of the app (TODO DEPLOY)
  -s <string>        Executes a remote script (TODO DEPOY)
  -e <string>        Adds the environment variable to config/env
  --no-compile-assets Skip assets compilation step
Return codes:
  0                  Upgrade terminated successfully
  1                  Configuration required
  2                  Aborted by user
  3                  Version not supported
  4                  Unexpected error\n" "$(basename "$0")" 1>&2
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
  version_check
  upgrade
  clean
}

proceed "$@"
