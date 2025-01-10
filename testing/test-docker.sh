#!/bin/sh

set -eu

# Set phpMyAdmin environment
PHPMYADMIN_HOSTNAME=${TESTSUITE_HOSTNAME:=localhost}
PHPMYADMIN_PORT=${TESTSUITE_PORT:=80}
PHPMYADMIN_URL=http://${PHPMYADMIN_HOSTNAME}:${PHPMYADMIN_PORT}/

# Set database environment
PHPMYADMIN_DB_HOSTNAME=${PMA_HOST:=localhost}
PHPMYADMIN_DB_PORT=${PMA_PORT:=3306}
TESTSUITE_USER=${TESTSUITE_USER:=root}
TESTSUITE_ROOT_PASSWORD=${TESTSUITE_ROOT_PASSWORD:-}

SUBJECT_CA="/C=US/O=phpMyAdmin testing/OU=Docker/CN=ssl-ca.phpmyadmin.local/emailAddress=ssl-ca@example.org"
SUBJECT_CLIENT="/C=US/O=phpMyAdmin testing/OU=Docker/CN=client.phpmyadmin.local/emailAddress=secure-user@example.org"

if [ "${TESTSUITE_USER}" = "root" ] && [ -n "${TESTSUITE_ROOT_PASSWORD}" ]; then
    echo "Do not use TESTSUITE_ROOT_PASSWORD with TESTSUITE_USER=root"
    exit 1
fi

TEST_CLI_ARGS=""
if [ -n "${TESTSUITE_HOSTNAME_ARBITRARY:-}" ]; then
    TEST_CLI_ARGS="$TEST_CLI_ARGS --server ${PHPMYADMIN_DB_HOSTNAME}"
fi

if [ -n "${TESTSUITE_ROOT_PASSWORD}" ]; then
    TEST_CLI_ARGS="$TEST_CLI_ARGS --root-password ${TESTSUITE_ROOT_PASSWORD}"
fi

# Find test script
if [ -f ./phpmyadmin_test.py ] ; then
    FILENAME=./phpmyadmin_test.py
else
    FILENAME=./testing/phpmyadmin_test.py
fi

SSL_FLAG="--skip-ssl"

if [ -n "${IS_USING_SSL:-}" ]; then
    SSL_FLAG="--ssl --ssl-verify-server-cert --ssl-ca=/etc/phpmyadmin/ssl/ca-cert.pem"
fi

mariadb $SSL_FLAG -h "${PHPMYADMIN_DB_HOSTNAME}" -P"${PHPMYADMIN_DB_PORT}" -u"$TESTSUITE_USER" -p"${TESTSUITE_PASSWORD}" -e "SELECT @@version;SHOW VARIABLES LIKE 'require_secure_transport';SHOW VARIABLES LIKE '%ssl%';"

if [ -n "${IS_USING_SSL:-}" ]; then
    set +e
    mariadb --skip-ssl -h "${PHPMYADMIN_DB_HOSTNAME}" -P"${PHPMYADMIN_DB_PORT}" -u"$TESTSUITE_USER" -p"${TESTSUITE_PASSWORD}" -e "SELECT @@version;SHOW VARIABLES LIKE 'require_secure_transport';" 1> /dev/null 2> /dev/null
    if [ $? != 1 ]; then
        echo "The server does not enforce SSL connections, stopping the test."
        exit 1
    fi
    set -e
fi

if  [ -n "${IS_USING_SSL:-}" ] && [ -n "${TESTSUITE_ROOT_PASSWORD}" ]; then
    mariadb $SSL_FLAG -h "${PHPMYADMIN_DB_HOSTNAME}" -P"${PHPMYADMIN_DB_PORT}" -u"root" -p"${TESTSUITE_ROOT_PASSWORD}" \
    -e "CREATE USER 'ssl-specific-user'@'%' REQUIRE SUBJECT '$SUBJECT_CLIENT' AND ISSUER '$SUBJECT_CA';"

    set +e
    mariadb $SSL_FLAG --ssl-cert=/etc/phpmyadmin/ssl/client-cert.pem --ssl-key=/etc/phpmyadmin/ssl/client-key.pem -h "${PHPMYADMIN_DB_HOSTNAME}" -P"${PHPMYADMIN_DB_PORT}" -u"ssl-specific-user" -e "SELECT @@version;SHOW VARIABLES LIKE 'require_secure_transport';" 1> /dev/null 2> /dev/null
    if [ $? != 0 ]; then
        echo "The server should accept the SSL client cert login, stopping the test."
        exit 1
    fi
    set -e

    set +e
    mariadb $SSL_FLAG -h "${PHPMYADMIN_DB_HOSTNAME}" -P"${PHPMYADMIN_DB_PORT}" -u"ssl-specific-user" -e "SELECT @@version;SHOW VARIABLES LIKE 'require_secure_transport';" 1> /dev/null 2> /dev/null
    if [ $? != 1 ]; then
        echo "The server should refuse the login without a client cert, stopping the test."
        exit 1
    fi
    set -e
fi

ret=$?

if [ $ret -ne 0 ] ; then
    echo "Could not connect to ${PHPMYADMIN_DB_HOSTNAME} on port ${PHPMYADMIN_DB_PORT}"
    exit $ret
fi

curl -fsSL --output /dev/null "${PHPMYADMIN_URL}"
ret=$?

if [ $ret -ne 0 ] ; then
    echo "Could not connect to ${PHPMYADMIN_URL}"
    exit $ret
fi

# Perform tests
ret=0
pytest -p no:cacheprovider -q --url "$PHPMYADMIN_URL" --username $TESTSUITE_USER --password "$TESTSUITE_PASSWORD" $TEST_CLI_ARGS $FILENAME
ret=$?

# Show debug output in case of failure
if [ $ret -ne 0 ] ; then
    ${COMMAND_HOST} ps faux
    echo "Result of ${PHPMYADMIN_DB_HOSTNAME} tests: FAILED"
    exit $ret
fi

echo "Result of ${PHPMYADMIN_DB_HOSTNAME} tests: SUCCESS"
