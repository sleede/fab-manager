#!/usr/bin/env bash

RAILS_ENV='test' bin/rails db:environment:set
RAILS_ENV='test' bin/rails db:drop
RAILS_ENV='test' bin/rails db:create
RAILS_ENV='test' bin/rails db:migrate
RAILS_ENV='test' bundle exec bin/rails test "$@"
