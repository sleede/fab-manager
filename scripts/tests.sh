#!/usr/bin/env bash

# Use this script to safely run the test suite after any database changes.
# This must be preferred over `rails test`.

stripe_public_key=$(RAILS_ENV='test' bin/rails runner "puts ENV['STRIPE_PUBLISHABLE_KEY']")
stripe_secret_key=$(RAILS_ENV='test' bin/rails runner "puts ENV['STRIPE_API_KEY']")
oauth2_client_id=$(RAILS_ENV='test' bin/rails runner "puts ENV['OAUTH_CLIENT_ID']")
oauth2_client_secret=$(RAILS_ENV='test' bin/rails runner "puts ENV['OAUTH_CLIENT_SECRET']")
oidc_client_id=$(RAILS_ENV='test' bin/rails runner "puts ENV['OIDC_CLIENT_ID']")
oidc_client_secret=$(RAILS_ENV='test' bin/rails runner "puts ENV['OIDC_CLIENT_SECRET']")
if [[ -z "$stripe_public_key" ]]; then
  read -rp "STRIPE_PUBLISHABLE_KEY is not set. Please input the public key now. > " stripe_public_key </dev/tty
  if [[ -z "$stripe_public_key" ]]; then echo "Key was not set, exiting..."; exit 1; fi
fi

if [[ -z "$stripe_secret_key" ]]; then
  read -rp "STRIPE_API_KEY is not set. Please input the secret key now. > " stripe_secret_key </dev/tty
  if [[ -z "$stripe_secret_key" ]]; then echo "Key was not set, exiting..."; exit 1; fi
fi
if [[ -z "$oauth2_client_id" ]]; then
  read -rp "OAUTH_CLIENT_ID is not set. Please input the client ID now. > " oauth2_client_id </dev/tty
  if [[ -z "$oauth2_client_id" ]]; then echo "Key was not set, exiting..."; exit 1; fi
fi

if [[ -z "$oauth2_client_secret" ]]; then
  read -rp "OAUTH_CLIENT_SECRET is not set. Please input the client secret now. > " oauth2_client_secret </dev/tty
  if [[ -z "$oauth2_client_secret" ]]; then echo "Key was not set, exiting..."; exit 1; fi
fi
if [[ -z "$oidc_client_id" ]]; then
  read -rp "OIDC_CLIENT_ID is not set. Please input the client ID now. > " oidc_client_id </dev/tty
  if [[ -z "$oidc_client_id" ]]; then echo "Key was not set, exiting..."; exit 1; fi
fi

if [[ -z "$oidc_client_secret" ]]; then
  read -rp "OIDC_CLIENT_SECRET is not set. Please input the client secret now. > " oidc_client_secret </dev/tty
  if [[ -z "$oidc_client_secret" ]]; then echo "Key was not set, exiting..."; exit 1; fi
fi

STRIPE_PUBLISHABLE_KEY="$stripe_public_key" STRIPE_API_KEY="$stripe_secret_key" \
OAUTH_CLIENT_ID="$oauth2_client_id" OAUTH_CLIENT_SECRET="$oauth2_client_secret" \
OIDC_CLIENT_ID="$oidc_client_id" OIDC_CLIENT_SECRET="$oidc_client_secret" RAILS_ENV='test' bin/rails test "$@"
