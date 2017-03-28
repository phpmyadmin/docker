#!/bin/sh

# Helper script to wait for testing inside container completes
# Needs running docker-compose container based on docker-compose.testing.yml

TIMEOUT=0

while [ `docker-compose -f docker-compose.testing.yml logs phpmyadmin | grep -c 'Result of \(mysql\|mariadb\) tests'` -lt 2 ] ; do
    echo Retry...
    sleep 1
    TIMEOUT=$(($TIMEOUT + 1))
    if [ $TIMEOUT -gt 10 ] ; then
        docker-compose -f docker-compose.testing.yml logs phpmyadmin
        echo 'Timeout!'
        exit 1
    fi
done

if [ `docker-compose -f docker-compose.testing.yml logs phpmyadmin | grep -c 'Result of \(mysql\|mariadb\) tests.*SUCCESS'` -lt 2 ] ; then
    docker-compose -f docker-compose.testing.yml logs phpmyadmin
    echo 'Failed!'
    exit 2
fi

exit 0
