#!/usr/bin/env bash
set -e

docker pull metaskills/mssql-server-linux-rails

container=$(docker ps -a -q --filter ancestor=metaskills/mssql-server-linux-rails)
if [[ -z $container ]]; then
  docker run -p 1433:1433 -d metaskills/mssql-server-linux-rails && sleep 10
  exit
fi

container=$(docker ps -q --filter ancestor=metaskills/mssql-server-linux-rails)
if [[ -z $container ]]; then
  docker start $container && sleep 10
fi
