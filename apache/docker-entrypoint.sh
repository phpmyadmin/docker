#!/bin/bash
if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ]; then

    if [ ! -f /etc/phpmyadmin/config.secret.inc.php ]; then
        cat > /etc/phpmyadmin/config.secret.inc.php <<EOT
<?php
\$cfg['blowfish_secret'] = '$(tr -dc 'a-zA-Z0-9~!@#$%^&*_()+}{?></";.,[]=-' < /dev/urandom | fold -w 32 | head -n 1)';
EOT
    fi
    chgrp www-data /etc/phpmyadmin/config.secret.inc.php

    if [ ! -f /etc/phpmyadmin/config.user.inc.php ]; then
        touch /etc/phpmyadmin/config.user.inc.php
    fi
fi

if [ ! -z "${HIDE_PHP_VERSION}" ]; then
    echo "PHP version is now hidden."
    echo -e 'expose_php = Off\n' > $PHP_INI_DIR/conf.d/phpmyadmin-hide-php-version.ini
fi

if [ ! -z "${PMA_CONFIG_BASE64}" ]; then
    echo "Adding the custom config.inc.php from base64."
    echo "${PMA_CONFIG_BASE64}" | base64 -d > /etc/phpmyadmin/config.inc.php
fi

if [ ! -z "${PMA_USER_CONFIG_BASE64}" ]; then
    echo "Adding the custom config.user.inc.php from base64."
    echo "${PMA_USER_CONFIG_BASE64}" | base64 -d > /etc/phpmyadmin/config.user.inc.php
fi

if [ ! -z "${PMA_SSL_CA_BASE64}" ]; then
    mkdir -p /etc/phpmyadmin/ssl
    echo "Adding the custom pma-ssl-ca from base64."
    echo "${PMA_SSL_CA_BASE64}" | base64 -d > /etc/phpmyadmin/ssl/pma-ssl-ca.pem
    export "PMA_SSL_CA"="/etc/phpmyadmin/ssl/pma-ssl-ca.pem"
fi

if [ ! -z "${PMA_SSL_KEY_BASE64}" ]; then
    mkdir -p /etc/phpmyadmin/ssl
    echo "Adding the custom pma-ssl-key from base64."
    echo "${PMA_SSL_KEY_BASE64}" | base64 -d > /etc/phpmyadmin/ssl/pma-ssl-key.key
    export "PMA_SSL_KEY"="/etc/phpmyadmin/ssl/pma-ssl-key.key"
fi

if [ ! -z "${PMA_SSL_CERT_BASE64}" ]; then
    mkdir -p /etc/phpmyadmin/ssl
    echo "Adding the custom pma-ssl-cert from base64."
    echo "${PMA_SSL_CERT_BASE64}" | base64 -d > /etc/phpmyadmin/ssl/pma-ssl-cert.pem
    export "PMA_SSL_CERT"="/etc/phpmyadmin/ssl/pma-ssl-cert.pem"
fi

if [ ! -z "${PMA_SSL_CAS_BASE64}" ]; then
    echo "Adding multiples custom pma-ssl-ca from base64."
    PMA_SSL_CAS=$(generate_ssl_files "${PMA_SSL_CAS_BASE64}" "CA" "pem")
    export "PMA_SSL_CAS"
fi

if [ ! -z "${PMA_SSL_KEYS_BASE64}" ]; then
    echo "Adding multiples custom pma-ssl-key from base64."
    PMA_SSL_KEYS=$(generate_ssl_files "${PMA_SSL_KEYS_BASE64}" "CERT" "cert")
    export "PMA_SSL_KEYS"
fi

if [ ! -z "${PMA_SSL_CERTS_BASE64}" ]; then
    echo "Adding multiples custom pma-ssl-cert from base64."
    PMA_SSL_CERTS=$(generate_ssl_files "${PMA_SSL_CERTS_BASE64}" "KEY" "key")
    export "PMA_SSL_CERTS"
fi

# start: Apache specific settings
if [ -n "${APACHE_PORT+x}" ]; then
    echo "Setting apache port to ${APACHE_PORT}."
    sed -i "/VirtualHost \*:80/c\\<VirtualHost \*:${APACHE_PORT}\>" /etc/apache2/sites-enabled/000-default.conf
    sed -i "/Listen 80/c\Listen ${APACHE_PORT}" /etc/apache2/ports.conf
    apachectl configtest
fi
# end: Apache specific settings

get_docker_secret() {
    local env_var="${1}"
    local env_var_file="${env_var}_FILE"

    # Check if the variable with name $env_var_file (which is $PMA_PASSWORD_FILE for example)
    # is not empty and export $PMA_PASSWORD as the password in the Docker secrets file

    if [[ -n "${!env_var_file}" ]]; then
        export "${env_var}"="$(cat "${!env_var_file}")"
    fi
}

# This function generates SSL files from a base64 encoded string.
# Arguments:
#   1. base64_string: A comma-separated string of base64 encoded SSL files.
#   2. prefix: A prefix to be used in the output file names.
#   3. extension: The file extension to be used for the output files.
# The function creates a directory for the SSL files, decodes each base64 string,
# writes the decoded content to a file, and returns a comma-separated list of the generated file paths.
# 
generate_ssl_files() {
    local base64_string="${1}"
    local output_dir="/etc/phpmyadmin/ssl"
    mkdir -p "${output_dir}"
    IFS=',' read -ra FILES <<< "${base64_string}"
    local counter=1
    local ssl_files=""
    for file in "${FILES[@]}"; do
        local output_file="${output_dir}/pma-ssl-${2}-${counter}.${3}"
        echo "${file}" | base64 -d > "${output_file}"
        ssl_files="${ssl_files}${output_file},"
        counter=$((counter + 1))
    done
    ssl_files="${ssl_files%,}"
    echo "${ssl_files}"
}

get_docker_secret PMA_USER
get_docker_secret PMA_PASSWORD
get_docker_secret MYSQL_ROOT_PASSWORD
get_docker_secret MYSQL_PASSWORD
get_docker_secret PMA_HOSTS
get_docker_secret PMA_HOST
get_docker_secret PMA_CONTROLHOST
get_docker_secret PMA_CONTROLUSER
get_docker_secret PMA_CONTROLPASS
get_docker_secret PMA_SSL
get_docker_secret PMA_SSLS

exec "$@"
