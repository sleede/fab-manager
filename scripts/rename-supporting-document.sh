#!/usr/bin/env bash

yq() {
  docker run --rm -i -v "${PWD}:/workdir" --user "$UID" mikefarah/yq:4 "$@"
}

config()
{
  echo -ne "Checking env file... "
  FABMANAGER_PATH=$(pwd)
  if [ ! -w "$FABMANAGER_PATH/config/env" ]; then
    echo "Fab-manager's environment file not found or not writable."
    echo "Please run this script from the installation folder, and as a user having write access on config/env"
    exit 1
  fi
  local _commands=("sed" "grep")
  for _command in "${_commands[@]}"; do
    echo "detecting $_command..."
    if ! command -v "$_command"
    then
      echo "Please install $_command before running this script."
      echo -e "\e[91m[ ❌ ] $_command was not found, exiting...\e[39m" && exit 1
    fi
  done
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

rename_dir()
{
  mv proof_of_identity_files supporting_document_files
}

rename_mount()
{
  if [[ $(yq eval ".services.$SERVICE.volumes.[] | select (. == \"*proof_of_identity_files\")" docker-compose.yml) ]]; then
    # change docker-compose.yml permissions for fix yq can't modify file issue
    chmod 666 docker-compose.yml
    yq -i eval "(.services.$SERVICE.volumes.[] | select (. == \"*proof_of_identity_files\")) = \"./supporting_document_files:/usr/src/app/supporting_document_files\"" docker-compose.yml
    chmod 644 docker-compose.yml
  fi
}

rename_var()
{
  current=$(grep -Po "MAX_PROOF_OF_IDENTITY_FILE_SIZE=\K.*" "$FABMANAGER_PATH/config/env")
  sed -i.bak "s/MAX_PROOF_OF_IDENTITY_FILE_SIZE=$current/MAX_SUPPORTING_DOCUMENT_FILE_SIZE=$current/g" "$FABMANAGER_PATH/config/env"
}

proceed()
{
  config
  rename_dir
  rename_mount
  rename_var
}

proceed "$@"
