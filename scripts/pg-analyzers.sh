#!/usr/bin/env bash

docker-compose exec -T postgres psql -Upostgres -c \\dFd | head -n -2 | tail -n +3 | awk '{ print gensub(/([a-z]+)_stem/,"\\1","g",$3); }'