#!/bin/sh

# Helper script to wait for testing inside container completes
# Needs running docker-compose container based on docker-compose.testing.yml

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No Color

TIMEOUT=0

sleep 5

while [ `docker-compose -f docker-compose.testing.yml logs phpmyadmin | grep -c 'Result of \(mysql\|mariadb\) tests'` -lt 2 ] ; do
    sleep 1
    TIMEOUT=$(($TIMEOUT + 1))
    if [ $TIMEOUT -gt 20 ] ; then
        docker-compose -f docker-compose.testing.yml logs phpmyadmin
        echo "${RED}Timeout!${NC}"
        exit 1
    fi
done

if [ `docker-compose -f docker-compose.testing.yml logs phpmyadmin | grep -c 'Result of \(mysql\|mariadb\) tests.*SUCCESS'` -lt 2 ] ; then
    docker-compose -f docker-compose.testing.yml logs phpmyadmin
    echo "${RED}Failed${NC}"
    exit 2
fi

docker-compose -f docker-compose.testing.yml logs phpmyadmin
echo "${GREEN}Success${NC}"
exit 0
