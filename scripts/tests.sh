#!/usr/bin/env bash

# Use this script to safely run the test suite after any database changes.
# This must be preferred over `rails test`.

stripe_public_key=$(RAILS_ENV='test' bin/rails runner "puts ENV['STRIPE_PUBLISHABLE_KEY']")
stripe_secret_key=$(RAILS_ENV='test' bin/rails runner "puts ENV['STRIPE_API_KEY']")
if [[ -z "$stripe_public_key" ]]; then
  read -rp "STRIPE_PUBLISHABLE_KEY is not set. Please input the public key now. > " stripe_public_key </dev/tty
  if [[ -z "$stripe_public_key" ]]; then echo "Key was not set, exiting..."; exit 1; fi
fi

if [[ -z "$stripe_secret_key" ]]; then
  read -rp "STRIPE_API_KEY is not set. Please input the secret key now. > " stripe_secret_key </dev/tty
  if [[ -z "$stripe_secret_key" ]]; then echo "Key was not set, exiting..."; exit 1; fi
fi

STRIPE_PUBLISHABLE_KEY="$stripe_public_key" STRIPE_API_KEY="$stripe_secret_key" RAILS_ENV='test' bin/rails test "$@"
