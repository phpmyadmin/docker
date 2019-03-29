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

    chown www-data:www-data /sessions /var/nginx/client_body_temp

    if ! [ -e index.php -a -e db_designer.php ]; then
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

exec "$@"
