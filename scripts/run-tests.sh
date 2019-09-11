#!/usr/bin/env bash

RAILS_ENV=test rake db:drop
RAILS_ENV=test rake db:create
RAILS_ENV=test rake db:migrate
rake test
