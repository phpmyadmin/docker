#!/bin/sh

NAME="$1"

if [ -n "$2" ] ; then
    PORT="$2"
    TESTSUITE_PORT=$2
fi

if [ -n "$3" ] ; then
    SERVER="--server $3"
    PMA_HOST=$3
else
    SERVER=''
fi

# Set PHPMyAdmin environment
PHPMYADMIN_HOSTNAME=${TESTSUITE_HOSTNAME:=localhost}
PHPMYADMIN_PORT=${TESTSUITE_PORT:=80}
PHPMYADMIN_URL=http://$PHPMYADMIN_HOSTNAME:$PORT/

# Set database environment
PHPMYADMIN_DB_HOSTNAME=${PMA_HOST:=localhost}
PHPMYADMIN_DB_PORT=${PMA_PORT:=3306}

# Color text output
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Find test script
if [ -f ./phpmyadmin_test.py ] ; then
    FILENAME=./phpmyadmin_test.py
else
    FILENAME=./testing/phpmyadmin_test.py
fi

# Check if script is running inside container
if ! [ -f /.dockerenv ] ; then
    echo "Tests running outside container..."
    COMMAND_HOST="docker exec ${NAME}"
    docker ps -a

    # Wait for database to start
    TIMEOUT=0
    while [ $(docker logs db_server 2>&1 | fgrep -c "mysqld: ready for connections.") -le 0 ] ; do
        echo "Waiting for ${PHPMYADMIN_DB_HOSTNAME} database start..."
        sleep 10
        TIMEOUT=$((TIMEOUT + 1))
        if [ $TIMEOUT -gt 3 ] ; then
            echo "Failed to connect ${PHPMYADMIN_DB_HOSTNAME} database!"
            echo "Result of ${PHPMYADMIN_DB_HOSTNAME} tests: ${RED}FAILED${NC}"
            docker logs ${NAME}
            exit 1
        fi
    done

    # Wait for container to start
    TIMEOUT=0
    while [ $(docker logs ${NAME} 2>&1 | fgrep -c "Command line: 'apache2 -D FOREGROUND'") -le 0 ] ; do
        echo "Waiting for PHPMyAdmin start..."
        sleep 1
        TIMEOUT=$((TIMEOUT + 1))
        if [ $TIMEOUT -gt 10 ] ; then
            echo "Failed to connect PHPMyAdmin!"
            echo "Result of ${PHPMYADMIN_DB_HOSTNAME} tests: ${RED}FAILED${NC}"
            docker logs ${NAME}
            exit 1
        fi
    done
else
    echo "Tests running inside container..."
    FILENAME=/phpmyadmin_test.py
fi

# Perform tests
ret=0
$FILENAME --url "$PHPMYADMIN_URL" --username root --password $TESTSUITE_PASSWORD $SERVER
ret=$?

# Show debug output in case of failure
if [ $ret -ne 0 ] ; then
    curl "$PHPMYADMIN_URL"
    ${COMMAND_HOST} ps faux
    echo "Result of ${PHPMYADMIN_DB_HOSTNAME} tests: ${RED}FAILED${NC}"
    exit $ret
fi

echo "Result of ${PHPMYADMIN_DB_HOSTNAME} tests: ${GREEN}SUCCESS${NC}"
