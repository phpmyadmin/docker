#!/bin/bash
if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ]; then
    if [ "$(id -u)" = '0' ]; then
        case "$1" in
            apache2*)
                user="${APACHE_RUN_USER:-www-data}"
                group="${APACHE_RUN_GROUP:-www-data}"
                ;;
            *) # php-fpm
                user='www-data'
                group='www-data'
                ;;
        esac
    else
        user="$(id -u)"
        group="$(id -g)"
    fi

    # Custom folders for sessions
    chown ${user}:${group} /sessions /var/nginx/client_body_temp

    if ! [ -e index.php -a -e url.php ]; then
        echo >&2 "phpMyAdmin not found in $PWD - copying now..."
        if [ "$(ls -A)" ]; then
            echo >&2 "WARNING: $PWD is not empty - press Ctrl+C now if this is an error!"
            ( set -x; ls -A; sleep 10 )
        fi
        tar --create \
            --file - \
            --one-file-system \
            --directory /usr/src/phpmyadmin \
            --owner "$user" --group "$group" \
            . | tar --extract --file -
        echo >&2 "Complete! phpMyAdmin has been successfully copied to $PWD"
        mkdir -p tmp; \
        chmod -R 777 tmp; \
    fi

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
    echo 'expose_php = Off' > $PHP_INI_DIR/conf.d/phpmyadmin-hide-php-version.ini
fi

UPLOAD_LIMIT_INI_FILE="$PHP_INI_DIR/conf.d/phpmyadmin-upload-limit.ini"
if [ ! -z "${UPLOAD_LIMIT}" ]; then
    echo "Adding the custom upload limit."
    echo -e "upload_max_filesize = $UPLOAD_LIMIT\npost_max_size = $UPLOAD_LIMIT\n" > $UPLOAD_LIMIT_INI_FILE
else
    if [ -f $UPLOAD_LIMIT_INI_FILE ]; then
        echo "Removing the custom upload limit."
        rm $UPLOAD_LIMIT_INI_FILE
    fi
fi

if [ ! -z "${PMA_CONFIG_BASE64}" ]; then
    echo "Adding the custom config.inc.php from base64."
    echo "${PMA_CONFIG_BASE64}" | base64 -d > /etc/phpmyadmin/config.inc.php
fi

if [ ! -z "${PMA_USER_CONFIG_BASE64}" ]; then
    echo "Adding the custom config.user.inc.php from base64."
    echo "${PMA_USER_CONFIG_BASE64}" | base64 -d > /etc/phpmyadmin/config.user.inc.php
fi

exec "$@"
