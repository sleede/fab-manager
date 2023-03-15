#!/usr/bin/env bash

jq() {
  docker run --rm -i -v "${PWD}:/data" --user "$UID" imega/jq "$@"
}

config() {
  PROJECT_ID="382064"
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

add_storage() {
  # param: FILE_PATH
  data=$(curl -s --data-binary "@$1" https://api.crowdin.com/api/v2/storages -H "$(authorization)" -H "Crowdin-API-FileName: $(basename "$1")" -H "Content-Type: text/yaml")
  echo "$data" | jq -r '.data.id'
}

list_files() {
  curl -s "https://api.crowdin.com/api/v2/projects/$PROJECT_ID/files" -H "$(authorization)"
}

update_file() {
  # params: FILE_ID, STORAGE_ID
  curl -s -X PUT "https://api.crowdin.com/api/v2/projects/$PROJECT_ID/files/$1" -H "$(authorization)" -H "Content-Type: application/json" -d "{ \"storageId\": $2 }"
}

find_file_id() {
  # param : FILE_PATH
  filename=$(basename "$1")
  list_files | jq -c "[ .data[] | select( .data.name == \"$filename\") ]" | jq -r ".[].data.id"
}

function trap_ctrlc()
{
  echo "Ctrl^C, exiting..."
  exit 2
}

run() {
  trap "trap_ctrlc" 2 # SIGINT
  config
  for file in "$SCRIPT_PATH"/../../config/locales/*en.yml; do
    if [[ ! "$file" =~ rails && ! "$file" =~ base && ! "$file" =~ devise ]]; then
      printf "\n\e[0;33m ⇧ uploading %s...\n\e[0m" "$(basename "$file")"
      storageId=$(add_storage "$file")
      update_file "$(find_file_id "$file")" "$storageId"
    fi
  done
}


run "$@"
