#!/bin/bash
if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ]; then

    if [ ! -f /etc/phpmyadmin/config.secret.inc.php ]; then
        cat > /etc/phpmyadmin/config.secret.inc.php <<EOT
<?php
\$cfg['blowfish_secret'] = '$(tr -dc 'a-zA-Z0-9~!@#$%^&*_()+}{?></";.,[]=-' < /dev/urandom | fold -w 32 | head -n 1)';
EOT
    fi

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

# Create a symlink for the www root dir to support sub-URI.
# See: https://stackoverflow.com/questions/42035947/how-to-change-the-access-url-of-official-phpmyadmin-docker-image-to-http-local/68643939#68643939
if [ -n "${PMA_SUB_URI_BASE}" ]; then
    echo "Using sub URI: ${PMA_SUB_URI_BASE}."
    # Create symlink if link target does not already exit.
    if [ ! -d /var/www/html/"${PMA_SUB_URI_BASE}" ] && [ ! -f /var/www/html/"${PMA_SUB_URI_BASE}" ]; then
        ln -s /var/www/html /var/www/html"${PMA_SUB_URI_BASE}"
        ## Verify creation.
        if [ -d /var/www/html"${PMA_SUB_URI_BASE}" ]; then
          echo "Sub URI link created."
        else
          echo "!! Creating sub-URI link failed. Validate PMA_SUB_URI_BASE. !!"
          exit 1
        fi
    # If symlink target exist, validate that it is a symlink.
    # Fail if the target is pointing to an existing file or dir like 'doc'.
    elif [ ! -L /var/www/html/"${PMA_SUB_URI_BASE}" ]; then
        echo "!! Sub URI '${PMA_SUB_URI_BASE}' invalid. Please change PMA_SUB_URI_BASE. Cannot create link since a file or directory with same name exists. !!"
        exit 1
    fi
fi

get_docker_secret() {
    local env_var="${1}"
    local env_var_file="${env_var}_FILE"

    # Check if the variable with name $env_var_file (which is $PMA_PASSWORD_FILE for example)
    # is not empty and export $PMA_PASSWORD as the password in the Docker secrets file

    if [[ -n "${!env_var_file}" ]]; then
        export "${env_var}"="$(cat "${!env_var_file}")"
    fi
}

get_docker_secret PMA_PASSWORD
get_docker_secret MYSQL_ROOT_PASSWORD
get_docker_secret MYSQL_PASSWORD
get_docker_secret PMA_HOSTS
get_docker_secret PMA_HOST
get_docker_secret PMA_CONTROLPASS

exec "$@"


