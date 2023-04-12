#!/bin/bash

DOMAINS=()

welcome_message()
{
  clear
  echo "#======================================================================#"
  echo -e "#\e[31m    ____  __   ____       _  _   __   __ _   __    ___  ____  ____    \e[0m#"
  echo -e "#\e[31m   (  __)/ _\ (  _ \ ___ ( \/ ) / _\ (  ( \ / _\  / __)(  __)(  _ \   \e[0m#"
  echo -e "#\e[31m    ) _)/    \ ) _ ((___)/ \/ \/    \/    //    \( (_ \ ) _)  )   /   \e[0m#"
  echo -e "#\e[31m   (__) \_/\_/(____/     \_)(_/\_/\_/\_)__)\_/\_/ \___/(____)(__\_)   \e[0m#"
  echo "#                                                                      #"
  echo "#======================================================================#"
  printf "\n                 Welcome to Fab-manager's setup assistant\n\n\n"
  echo "Thank you for installing Fab-manager."
  printf "This script will guide you through the installation process of Fab-manager\n\n"
  echo -e "Please report any \e[1mfeedback or improvement request\e[0m on https://feedback.fab-manager.com/"
  echo -e "For \e[1mbug reports\e[0m, please open a new issue on https://github.com/sleede/fab-manager/issues"
  echo -e "You can call for \e[1mcommunity assistance\e[0m on https://forum.fab-manager.com/"
  printf "\nYou can interrupt this installation at any time by pressing Ctrl+C\n"
  printf "If you do not feel confortable with this installation, you can \e[4msubscribe to our hosting offers\e[0m:\nhttps://www.fab-manager.com/saas-offer\n\n"
  read -rp "Continue? (Y/n) " confirm </dev/tty
  if [[ "$confirm" = "n" ]]; then exit 1; fi
}

system_requirements()
{
  if is_root; then
    echo "It is not recommended to run this script as root. As a normal user, elevation will be prompted if needed."
    read -rp "Continue anyway? (Y/n) " confirm </dev/tty
    if [[ "$confirm" = "n" ]]; then exit 1; fi
  else
    if [ "$(has_sudo)" = 'no_sudo' ]; then
      echo "You are not allowed to sudo. Please add $(whoami) to the sudoers before continuing."
      exit 1
    fi
    local _groups=("docker")
    for _group in "${_groups[@]}"; do
      echo -e "detecting group $_group for current user..."
      if ! groups | grep "$_group"; then
        echo "Please add your current user to the $_group group."
        echo "You can run the following as root: \"usermod -aG $_group $(whoami)\", then logout and login again"
        echo -e "\e[91m[ ❌ ] current user is misconfigured, exiting...\e[39m" && exit 1
      fi
    done
  fi
  local _commands=("sudo" "curl" "sed" "openssl" "docker" "systemctl")
  for _command in "${_commands[@]}"; do
    echo "detecting $_command..."
    if ! command -v "$_command"
    then
      echo "Please install $_command before running this script."
      echo -e "\e[91m[ ❌ ] $_command was not found, exiting...\e[39m" && exit 1
    fi
  done
  echo "detecting docker version..."
  DOCKER_VERSION=$(docker -v | grep -oP "([0-9]{1,}\.)+[0-9]{1,}")
  if verlt "$DOCKER_VERSION" 20.10; then
    echo -e "\e[91m[ ❌ ] The installed docker version ($DOCKER_VERSION) is lower than the minimum required version (20.10). Exiting...\e[39m" && exit 1
  fi
  echo "detecting docker-compose..."
  docker-compose version
  printf "\e[92m[ ✔ ] All requirements successfully checked.\e[39m \n\n"
}

# compare versions utilities
# https://stackoverflow.com/a/4024263/1039377
verlte() {
    [  "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
}
verlt() {
    [ "$1" = "$2" ] && return 1 || verlte "$1" "$2"
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

is_root()
{
  return $(id -u)
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

read_email()
{
  local email
  read -rep "Please input a valid email address > " email </dev/tty
  if [[ "$email" == *"@"*"."* ]]; then
    EMAIL="$email"
  else
    read_email
  fi
}

config()
{
  SERVICE="fabmanager"
  # http_proxy should have been exported externally
  # shellcheck disable=SC2154
  if [ "$http_proxy" != "" ]; then
    read -rp "You seems to be behind a proxy. Do you want to configure a custom CA certificate? (Y/n) " confirm </dev/tty
    if [[ "$confirm" != "n" ]]; then
      echo "Paste the certificate below and terminate with an empty line:"
      CERTIFICATE=$(sed '/^$/q' </dev/tty)
    fi
  fi
  echo 'We recommend nginx to serve the application over the network (internet). You can use your own solution or let this script install and configure nginx for Fab-manager.'
  printf 'If you want to install Fab-manager behind a reverse proxy, you may not need to install the integrated nginx.\n'
  read -rp 'Do you want install nginx? (Y/n) ' NGINX </dev/tty
  if [ "$NGINX" != "n" ]; then
    # if the user doesn't want nginx, let him use its own solution for HTTPS
    printf "\n\nWe highly recommend to secure the application with HTTPS. You can use your own certificate or let this script install and configure let's encrypt for Fab-manager."
    printf "\nIf this server is publicly available on the internet, you can use Let's encrypt to automatically generate and renew a valid SSL certificate for free.\n"
    read -rp "Do you want install let's encrypt? (Y/n) " LETSENCRYPT </dev/tty
    if [ "$LETSENCRYPT" != "n" ]; then
      printf "\n\nLet's encrypt requires an email address to receive notifications about certificate expiration.\n"
      read_email
    fi
    # if the user wants to install nginx, configure the domains
    printf "\n\nWhat's the domain name where the instance will be active (eg. fab-manager.com)?\n"
    read_domain
    MAIN_DOMAIN=("${DOMAINS[0]}")
    OTHER_DOMAINS=${DOMAINS[*]/$MAIN_DOMAIN}
  else
    LETSENCRYPT="n"
  fi
}

read_domain()
{
  read -rep 'Please input the domain name > ' domain </dev/tty
  if [[ "$domain" == *"."* ]]; then
    DOMAINS+=("$domain")
  else
    echo "The domain name entered is invalid"
    read_domain
    return
  fi
  read -rp 'Do you have any other domain (eg. a www. alias)? (y/N) ' confirm </dev/tty
  if [ "$confirm" == "y" ]; then
    read_domain
  fi
}

prepare_files()
{
  FABMANAGER_PATH=${1:-/apps/fabmanager}

  echo -e "Fab-Manager will be installed in \e[31m$FABMANAGER_PATH\e[0m"
  read -rp "Continue? (Y/n) " confirm </dev/tty
  if [[ "$confirm" = "n" ]]; then exit 1; fi

  elevate_cmd mkdir -p "$FABMANAGER_PATH"
  elevate_cmd chown -R "$(whoami)" "$FABMANAGER_PATH"

  # create folders before starting the containers, otherwise root will own them
  local folders=(accounting config elasticsearch/config exports imports invoices log payment_schedules plugins postgresql \
  supporting_document_files public/packs public/uploads)
  for folder in "${folders[@]}"; do
    mkdir -p "$FABMANAGER_PATH/$folder"
  done

  # Fab-manager environment variables
  \curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/setup/env.example > "$FABMANAGER_PATH/config/env"

  # Fab-manager auth provider configuration file
  touch "$FABMANAGER_PATH/config/auth_provider.yml"

  # nginx configuration
  if [ "$NGINX" != "n" ]; then
    mkdir -p "$FABMANAGER_PATH/config/nginx"

    \curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/setup/nginx_with_ssl.conf.example > "$FABMANAGER_PATH/config/nginx/fabmanager.conf.ssl"
    \curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/setup/nginx.conf.example > "$FABMANAGER_PATH/config/nginx/fabmanager.conf"
  fi

  # let's encrypt configuration
  if [ "$LETSENCRYPT" != "n" ]; then
    mkdir -p "$FABMANAGER_PATH/letsencrypt/etc/config"
    mkdir -p "$FABMANAGER_PATH/letsencrypt/systemd"
    mkdir -p "$FABMANAGER_PATH/letsencrypt/etc/webrootauth"

    \curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/setup/webroot.ini.example > "$FABMANAGER_PATH/letsencrypt/etc/config/webroot.ini"
    # temp systemd files
    \curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/setup/letsencrypt.service > "$FABMANAGER_PATH/letsencrypt/systemd/letsencrypt.service"
    \curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/setup/letsencrypt.timer > "$FABMANAGER_PATH/letsencrypt/systemd/letsencrypt.timer"
  fi

  # ElasticSearch configuration files
  \curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/setup/elasticsearch.yml > "$FABMANAGER_PATH/elasticsearch/config/elasticsearch.yml"
  \curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/setup/log4j2.properties > "$FABMANAGER_PATH/elasticsearch/config/log4j2.properties"

  # docker-compose
  \curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/setup/docker-compose.yml > "$FABMANAGER_PATH/docker-compose.yml"

  # proxy
  if [ "$CERTIFICATE" != "" ]; then
    mkdir -p "$FABMANAGER_PATH/config/proxy"
    echo "$CERTIFICATE" > "$FABMANAGER_PATH/config/proxy/certificate.pem"
    \curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/setup/proxy/.npmrc > "$FABMANAGER_PATH/config/proxy/.npmrc"
    \curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/setup/proxy/gitconfig > "$FABMANAGER_PATH/config/proxy/gitconfig"
  fi
}

yq() {
  docker run --rm -i -v "${FABMANAGER_PATH}:/workdir" --user "$UID" mikefarah/yq:4 "$@"
}

bat() {
  docker run --rm -i -v "${PWD}:/workdir"  --user "$UID" sleede/bat:latest "$@"
}

prepare_nginx()
{
  if [ "$NGINX" != "n" ]; then
    sed -i.bak "s/MAIN_DOMAIN/${MAIN_DOMAIN[0]}/g" "$FABMANAGER_PATH/config/nginx/fabmanager.conf"
    sed -i.bak "s/MAIN_DOMAIN/${MAIN_DOMAIN[0]}/g" "$FABMANAGER_PATH/config/nginx/fabmanager.conf.ssl"
    sed -i.bak "s/ANOTHER_DOMAIN_1/$OTHER_DOMAINS/g" "$FABMANAGER_PATH/config/nginx/fabmanager.conf.ssl"
    sed -i.bak "s/URL_WITH_PROTOCOL_HTTPS/https:\/\/${MAIN_DOMAIN[0]}/g" "$FABMANAGER_PATH/config/nginx/fabmanager.conf.ssl"
  else
    # if nginx is not installed, remove its associated block from docker-compose.yml
    echo "Removing nginx..."
    yq -i eval 'del(.services.nginx)' docker-compose.yml
    printf "The two following configurations are useful if you want to install Fab-manager behind a reverse proxy...\n"
    read -rp "- Do you want to map the Fab-manager's service to an external network? (Y/n) " confirm </dev/tty
    if [ "$confirm" != "n" ]; then
      read -rep "Please input the name of the external network (default: web) " network </dev/tty
      if [ "$network" = "" ]; then network="web"; fi

      echo "Adding a network configuration to the docker-compose.yml file..."
      yq -i eval ".networks.$network.external = true" docker-compose.yml
      yq -i eval '.networks.db = "" | .networks.db tag="!!null"' docker-compose.yml
      yq -i eval '.services.fabmanager.networks += ["web"]' docker-compose.yml
      yq -i eval '.services.fabmanager.networks += ["db"]' docker-compose.yml
      yq -i eval '.services.postgres.networks += ["db"]' docker-compose.yml
      yq -i eval '.services.elasticsearch.networks += ["db"]' docker-compose.yml
      yq -i eval '.services.redis.networks += ["db"]' docker-compose.yml
      if ! docker network inspect "$network" 1>/dev/null; then
        echo "Creating the external network $network..."
        docker network create "$network"
      fi
    fi
    read -rp "- Do you want to rename the Fab-manager's service? (Y/n) " confirm </dev/tty
    if [ "$confirm" != "n" ]; then
      current="$(yq eval '.services.*.image | select(. == "sleede/fab-manager*") | path | .[-2]' docker-compose.yml)"
      printf "=======================\n- \e[1mCurrent value: %s\e[21m\n- New value? (leave empty to keep the current value)\n" "$current"
      read -rep "  > " value </dev/tty
      echo "======================="
      if [ "$value" != "" ]; then
        escaped=$(printf '%s\n' "$value" | iconv -f utf8 -t ascii//TRANSLIT//IGNORE | sed -e 's/[^a-zA-Z0-9-]/_/g')
        yq -i eval ".services.$escaped = .services.$current | del(.services.$current)" docker-compose.yml
        SERVICE="$escaped"
      fi
    fi
  fi
}

function join_by { local IFS="$1"; shift; echo "$*"; }

prepare_letsencrypt()
{
  if [ "$LETSENCRYPT" != "n" ]; then
    if ! openssl dhparam -in "$FABMANAGER_PATH/config/nginx/ssl/dhparam.pem" -check; then
      mkdir -p "$FABMANAGER_PATH/config/nginx/ssl"
      printf "\n\nNow, we will generate a Diffie-Hellman (DH) 4096 bits encryption key, to encrypt connections. This will take a moment, please wait...\n"
      openssl dhparam -out "$FABMANAGER_PATH/config/nginx/ssl/dhparam.pem" 4096
    fi
    sed -i.bak "s/REPLACE_WITH_YOUR@EMAIL.COM/$EMAIL/g" "$FABMANAGER_PATH/letsencrypt/etc/config/webroot.ini"
    sed -i.bak "s/MAIN_DOMAIN, ANOTHER_DOMAIN_1/$(join_by , "${DOMAINS[@]}")/g" "$FABMANAGER_PATH/letsencrypt/etc/config/webroot.ini"
    echo "Now downloading and configuring the certificate signing bot..."
    docker pull certbot/certbot:latest
    sed -i.bak "s:/apps/fabmanager:$FABMANAGER_PATH:g" "$FABMANAGER_PATH/letsencrypt/systemd/letsencrypt.service"
    elevate_cmd cp "$FABMANAGER_PATH/letsencrypt/systemd/letsencrypt.service" /etc/systemd/system/letsencrypt.service
    elevate_cmd cp "$FABMANAGER_PATH/letsencrypt/systemd/letsencrypt.timer" /etc/systemd/system/letsencrypt.timer
    elevate_cmd systemctl daemon-reload
  fi
}

prepare_docker()
{
  if [ "$(docker ps | wc -l)" -gt 1 ]; then
    printf "\n\nIf you have previously interrupted the installer, it is recommended to stop any existing docker container before continuing.\n"
    echo "Here's a list of all existing containers:"
    docker ps -a
    read -rp "Force remove all containers? (y/N) " confirm </dev/tty
    if [ "$confirm" = "y" ]; then
      # shellcheck disable=SC2046
      docker rm -f $(docker ps -q)
    fi
  fi

  # set the current user in the docker-compose.yml, as the owner of the process
  sed -i.bak "s/USER_ID/$(id -u):$(id -g)/g" "$FABMANAGER_PATH/docker-compose.yml"

  # if a certificate was provided, modify the docker-compose.yml file to use it
  if [ "$CERTIFICATE" != "" ]; then
    echo "Using the certificate provided..."
    yq -i eval ".services.$SERVICE.volumes += [\"./config/proxy/certificate.pem:/etc/ssl/certs/ca-cert-proxy.pem\"]" docker-compose.yml
    yq -i eval ".services.$SERVICE.volumes += [\"./config/proxy/.npmrc:/usr/src/app/.npmrc\"]" docker-compose.yml
    yq -i eval ".services.$SERVICE.volumes += [\"./config/proxy/gitconfig:/etc/gitconfig\"]" docker-compose.yml
  fi

  cd "$FABMANAGER_PATH" && docker-compose pull
}

get_md_anchor()
{
  local md_file="$1"
  local anchor="$2"

  local section lastline
  section=$(echo "$md_file" | sed -n "/<a name=\"$anchor/,/<a name=/p" | tail -n +2)
  lastline=$(echo "$section" | tail -n -1)
  if [[ "$lastline" == *"<a name="* ]]; then
    section=$(echo "$section" | head -n -1)
  fi
  echo "$section"
}

configure_env_file()
{
  # pre-configure the main domain
  if [ "${MAIN_DOMAIN[0]}" != "" ]; then
    sed -i.bak "s/DEFAULT_HOST=.*/DEFAULT_HOST=${MAIN_DOMAIN[0]}/g" "$FABMANAGER_PATH/config/env"
  fi

  # we automatically generate the SECRET_KEY_BASE
  secret=$(docker-compose -f "$FABMANAGER_PATH/docker-compose.yml" run --rm "$SERVICE" bundle exec rake secret)
  sed -i.bak "s/SECRET_KEY_BASE=/SECRET_KEY_BASE=$secret/g" "$FABMANAGER_PATH/config/env"

  printf "\n\nWe will now configure the environment variables.\n"
  echo "This allows you to customize Fab-manager's appearance and behavior."
  read -rp "Proceed? (Y/n) " confirm </dev/tty
  if [ "$confirm" = "n" ]; then return; fi

  local doc variables secret
  doc=$(\curl -sSL https://raw.githubusercontent.com/sleede/fab-manager/master/doc/environment.md)
  variables=(DEFAULT_HOST DEFAULT_PROTOCOL DELIVERY_METHOD SMTP_ADDRESS SMTP_PORT SMTP_USER_NAME SMTP_PASSWORD SMTP_AUTHENTICATION \
   SMTP_ENABLE_STARTTLS_AUTO SMTP_OPENSSL_VERIFY_MODE SMTP_TLS LOG_LEVEL MAX_IMAGE_SIZE MAX_CAO_SIZE MAX_IMPORT_SIZE MAX_SUPPORTING_DOCUMENT_FILE_SIZE \
   ADMINSYS_EMAIL APP_LOCALE RAILS_LOCALE MOMENT_LOCALE SUMMERNOTE_LOCALE ANGULAR_LOCALE FULLCALENDAR_LOCALE INTL_LOCALE INTL_CURRENCY\
   POSTGRESQL_LANGUAGE_ANALYZER TIME_ZONE WEEK_STARTING_DAY D3_DATE_FORMAT UIB_DATE_FORMAT EXCEL_DATE_FORMAT DISK_SPACE_MB_ALERT)
  for variable in "${variables[@]}"; do
    local var_doc current
    var_doc=$(get_md_anchor "$doc" "$variable")
    current=$(grep "$variable=" "$FABMANAGER_PATH/config/env")
    echo "$var_doc" | bat --file-name "$variable" --language md --color=always
    printf -- "- \e[1mCurrent value: %s\e[0m\n- New value? (leave empty to keep the current value)\n" "$current"
    read -rep "  > " value </dev/tty
    if [ "$value" != "" ]; then
      esc_val=$(printf '%s\n' "$value" | sed -e 's/\//\\\//g')
      esc_curr=$(printf '%s\n' "$current" | sed -e 's/\//\\\//g')
      sed -i.bak "s/$esc_curr/$variable=$esc_val/g" "$FABMANAGER_PATH/config/env"
    fi
  done

  # if DEFAULT_PROTOCOL was set to http, ALLOW_INSECURE_HTTP is probably required
  if grep "^DEFAULT_PROTOCOL=http$" "$FABMANAGER_PATH/config/env" 1>/dev/null; then
    get_md_anchor "$doc" "ALLOW_INSECURE_HTTP" | bat --file-name "ALLOW_INSECURE_HTTP" --language md --color=always
    printf "You have set \e[1mDEFAULT_PROTOCOL\e[0m to \e[1mhttp\e[21m.\n"
    read -rp "Do you want to allow insecure HTTP? (Y/n) " confirm </dev/tty
    if [ "$confirm" != "n" ]; then
      sed -i.bak "s/ALLOW_INSECURE_HTTP=.*/ALLOW_INSECURE_HTTP=true/g" "$FABMANAGER_PATH/config/env"
    fi
  fi
}

read_password()
{
  local password confirmation
  >&2 echo "Please input a password for this administrator's account"
  read -rsp " > " password </dev/tty
  if [ ${#password} -lt 12 ]; then
    >&2 printf "\nError: password is too short (minimal length: 12 characters)\n"
    password=$(read_password 'no-confirm')
  fi
  if [[ ! $password =~ [0-9] || ! $password =~ [a-z] || ! $password =~ [A-Z] || ! $password =~ [[:punct:]] ]]; then
    >&2 printf "\nError: password is too weak (should contain uppercases, lowercases, digits and special characters)\n"
    password=$(read_password 'no-confirm')
  fi
  if [ "$1" != 'no-confirm' ]; then
    >&2 printf "\nConfirm the password\n"
    read -rsp " > " confirmation </dev/tty
    if [ "$password" != "$confirmation" ]; then
      >&2 printf "\nError: passwords mismatch\n"
      password=$(read_password)
    fi
  fi
  echo "$password"
}

setup_assets_and_databases()
{
  printf "\n\nWe will now setup the database.\n"
  read -rp "Continue? (Y/n) " confirm </dev/tty
  if [ "$confirm" = "n" ]; then return; fi

  # create the database
  docker-compose -f "$FABMANAGER_PATH/docker-compose.yml" run --rm "$SERVICE" bundle exec rails db:create </dev/tty
  docker-compose -f "$FABMANAGER_PATH/docker-compose.yml" run --rm "$SERVICE" bundle exec rails db:schema:load </dev/tty

  # prompt default admin email/password
  printf "\n\nWe will now create the default administrator of Fab-manager.\n"
  read_email
  PASSWORD=$(read_password)
  printf "\nOK. We will fill the database now...\n"
  docker-compose -f "$FABMANAGER_PATH/docker-compose.yml" run --rm -e ADMIN_EMAIL="$EMAIL" -e ADMIN_PASSWORD="$PASSWORD" "$SERVICE" bundle exec rake db:seed </dev/tty # seed the database

  # now build the assets
  if ! docker-compose -f "$FABMANAGER_PATH/docker-compose.yml" run --user "0:0" --rm "$SERVICE" bundle exec rake assets:precompile </dev/tty; then
    echo -e "\e[91m[ ❌ ] someting went wrong while compiling the assets, exiting...\e[39m" && exit 1
  fi

  # and prepare elasticsearch
  docker-compose -f "$FABMANAGER_PATH/docker-compose.yml" run --rm "$SERVICE" bundle exec rake fablab:es:build_stats </dev/tty
}

stop()
{
  docker-compose -f "$FABMANAGER_PATH/docker-compose.yml" down
}

start()
{
  docker-compose -f "$FABMANAGER_PATH/docker-compose.yml" up -d
}

enable_ssl()
{
  if [ "$LETSENCRYPT" != "n" ]; then
    # generate certificate
    elevate_cmd systemctl start letsencrypt.service
    # serve http content over ssl
    mv "$FABMANAGER_PATH/config/nginx/fabmanager.conf" "$FABMANAGER_PATH/config/nginx/fabmanager.conf.nossl"
    mv "$FABMANAGER_PATH/config/nginx/fabmanager.conf.ssl" "$FABMANAGER_PATH/config/nginx/fabmanager.conf"
    stop
    start
    elevate_cmd systemctl enable letsencrypt.timer
    elevate_cmd systemctl start letsencrypt.timer
  fi
}

final_message()
{
  printf "\n\e[92m[ ✔ ] Installation process in now complete.\e[39m \n\n"
  echo "#========================#"
  echo -e "#\e[5m  🥳 Congratulations! 🎉  \e[25m#"
  echo "#========================#"
  printf "\n\n"
  echo -e "Please \e[1mkeep track of the logs\e[21m produced by this script and check that everything is running correctly."
  echo "You can call for the community assistance on https://forum.fab-manager.com"
  echo -e "We wish you a pleasant use of \e[31mFab-manager\e[0m"
}

function trap_ctrlc()
{
  echo "Ctrl^C, exiting..."
  exit 2
}

setup()
{
  trap "trap_ctrlc" 2 # SIGINT
  welcome_message
  system_requirements
  config
  prepare_files "$@"
  prepare_nginx
  prepare_letsencrypt
  prepare_docker
  configure_env_file
  setup_assets_and_databases
  start
  enable_ssl
  final_message
}

setup "$@"
