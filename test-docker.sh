#!/bin/sh

set -x

NAME=$1
PORT=$2
if [ -n "$3" ] ; then
    SERVER=$3
else
    SERVER=db
fi

URL=http://127.0.0.1:$PORT/
URL=http://localhost/phpmyadmin/

# Wait for container to start
while ! docker exec $NAME ps aux | grep -q nginx ; do echo 'Waiting for start...'; sleep 1; done

# Perform tests
python phpmyadmin_test.py --url "http://127.0.0.1:$PORT/" --username root --password -my-secret-pw --server $SERVER
if [ $ret -ne 0 ] ; then
    curl http://127.0.0.1:$PORT/
    docker ps -a
    docker exec $NAME ps faux
    docker exec $NAME cat /var/log/php7.0-fpm.log
    docker exec $NAME cat /var/log/nginx-error.log
    exit $ret
fi
