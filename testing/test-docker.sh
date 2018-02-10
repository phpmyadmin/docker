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

# Color text output
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No Color

ret=0
# Check if script is running inside container
if [ -f /.dockerenv ] ; then
    echo "Tests running inside container..."

    # Set database environment
    PHPMYADMIN_DB_HOSTNAME=${PMA_HOST:=localhost}
    PHPMYADMIN_DB_PORT=${PMA_PORT:=3306}
    PHPMYADMIN_DB_URL=http://$PHPMYADMIN_DB_HOSTNAME:$PHPMYADMIN_DB_PORT/

    # Wait for database to start
    TIMEOUT=0
    while ! curl "$PHPMYADMIN_DB_URL" &>/dev/null; do
        echo "Waiting for ${PHPMYADMIN_DB_HOSTNAME} database start..."
        sleep 10
        TIMEOUT=$((TIMEOUT + 1))
        if [ $TIMEOUT -gt 3 ] ; then
            echo "Failed to connect ${PHPMYADMIN_DB_HOSTNAME} database!"
            echo "Result of ${PHPMYADMIN_DB_HOSTNAME} tests: ${RED}FAILED${NC}"
            ret=1
            exit 1
        fi
    done
else
    echo "Tests running outside container..."
    docker ps -a
    COMMAND_HOST="docker exec ${NAME}"
fi

# Wait for container to start
TIMEOUT=0
while ! $COMMAND_HOST ps aux | grep -q nginx ; do
    echo "Waiting for PHPMyAdmin start..."
    sleep 1
    TIMEOUT=$((TIMEOUT + 1))
    if [ $TIMEOUT -gt 10 ] ; then
        echo "Failed to connect PHPMyAdmin!"
        echo "Result of ${PHPMYADMIN_DB_HOSTNAME} tests: ${RED}FAILED${NC}"
        ret=1
        exit 1
    fi
done

# Perform tests
if [ $ret -eq 0 ] ; then
    if [ -f /phpmyadmin_test.py ] ; then
        FILENAME=/phpmyadmin_test.py
    elif [ -f ./phpmyadmin_test.py ] ; then
        FILENAME=./phpmyadmin_test.py
    else
        FILENAME=./testing/phpmyadmin_test.py
    fi
    python $FILENAME --url "$PHPMYADMIN_URL" --username root --password $TESTSUITE_PASSWORD $SERVER
    ret=$?
fi

# Show debug output in case of failure
if [ $ret -ne 0 ] ; then
    curl "$PHPMYADMIN_URL"
    $COMMAND_HOST ps faux
    $COMMAND_HOST cat /var/log/php-fpm.log
    $COMMAND_HOST cat /var/log/nginx-error.log
    $COMMAND_HOST cat /var/log/supervisord.log
    echo "Result of ${PHPMYADMIN_DB_HOSTNAME} tests: ${RED}FAILED${NC}"
    exit $ret
fi

echo "Result of ${PHPMYADMIN_DB_HOSTNAME} tests: ${GREEN}SUCCESS${NC}"
