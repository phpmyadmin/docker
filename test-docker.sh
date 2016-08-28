#!/bin/sh

set -e
set -x

NAME=$1
PORT=$2

while ! docker exec $NAME ps aux | grep -q nginx ; do echo 'Waiting for start...'; sleep 1; done
docker ps -a
docker exec $NAME ps faux
curl http://127.0.0.1:$PORT/ | grep -q input_password
curl --cookie-jar /tmp/cj --location -d pma_username=root -d pma_password=my-secret-pw -d server=1 http://127.0.0.1:$PORT/ | grep -r 'db via TCP'
docker exec $NAME cat /var/log/php7.0-fpm.log
docker exec $NAME cat /var/log/nginx-error.log
