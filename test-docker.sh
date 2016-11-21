#!/bin/sh

set -x

NAME="$1"
PORT="$2"
if [ -n "$3" ] ; then
    SERVER="--server $3"
else
    SERVER=''
fi

URL=http://127.0.0.1:$PORT/

# Wait for container to start
ret=0
TIMEOUT=0
while ! docker exec "$NAME" ps aux | grep -q nginx ; do
    echo 'Waiting for start...'
    sleep 1
    TIMEOUT=$((TIMEOUT + 1))
    if [ $TIMEOUT -gt 10 ] ; then
        echo "Failed to wait!"
        ret=1
        exit 1
    fi
done

# Perform tests
if [ $ret -eq 0 ] ; then
    python phpmyadmin_test.py --url "$URL" --username root --password my-secret-pw $SERVER
    ret=$?
fi

# Show debug output in case of failure
if [ $ret -ne 0 ] ; then
    curl "$URL"
    docker ps -a
    docker exec "$NAME" ps faux
    docker exec "$NAME" cat /var/log/php-fpm.log
    docker exec "$NAME" cat /var/log/nginx-error.log
    docker exec "$NAME" cat /var/log/supervisord.log
    exit $ret
fi

# List processes
docker exec "$NAME" ps faux
