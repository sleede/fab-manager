#!/usr/bin/env bash

jq() {
  docker run --rm -i -v "${PWD}:/data" --user "$UID" imega/jq "$@"
}

config() {
  PROJECT_ID="382064"
  DIRECTORY_ID="5"
  TEMP_FILE="/tmp/Fab-manager-translations-$RANDOM.zip"
  SCRIPT_PATH=$(dirname "$0")
  TOKEN_FILE="$SCRIPT_PATH/../../.crowdin"
  if test -f "$TOKEN_FILE"; then
    ACCESS_TOKEN=$(cat "$TOKEN_FILE")
  else
    printf "\e[91m[ ❌] file %s does not exists.\e[0m Please configure your API access token first.\n" "$(basename "$TOKEN_FILE")"
    echo
    exit 1
  fi

}

authorization() {
  echo "Authorization: Bearer $ACCESS_TOKEN"
}

build_translations() {
  data=$(curl -s -X POST "https://api.crowdin.com/api/v2/projects/$PROJECT_ID/translations/builds/directories/$DIRECTORY_ID" -H "$(authorization)" -H "Content-Type: application/json" -d "{}")
  echo "$data" | jq -r '.data.id'
}

check_build_status() {
  # param: BUILD_ID
  data=$(curl -s "https://api.crowdin.com/api/v2/projects/$PROJECT_ID/translations/builds/$1" -H "$(authorization)")
  echo "$data" | jq -r '.data.status'
}

download_translations() {
  # param: BUILD_ID
  data=$(curl -s "https://api.crowdin.com/api/v2/projects/$PROJECT_ID/translations/builds/$1/download" -H "$(authorization)")
  echo "$data" | jq -r '.data.url'
}


function trap_ctrlc()
{
  echo "Ctrl^C, exiting..."
  exit 2
}

run() {
  trap "trap_ctrlc" 2 # SIGINT
  config
  printf "\n\e[0;33m 🛠 building the translations...\e[0m"
  BUILD_ID=$(build_translations)
  printf "\n\e[0;33m ↻ waiting for the translations build to complete...\e[0m"
  while [[ $(check_build_status "$BUILD_ID") != 'finished' ]]; do
    printf "."
    sleep 1
  done
  printf "\n\e[0;33m ⇩ downloading translations...\n\e[0m"
  DOWNLOAD_URL=$(download_translations "$BUILD_ID")
  curl -L -o "$TEMP_FILE" "$DOWNLOAD_URL"
  printf "\n\e[0;33m 📦 extracting translations...\n\e[0m"
  unzip -o "$TEMP_FILE" -d "$SCRIPT_PATH/../../"
  rm "$TEMP_FILE"
}


run "$@"
