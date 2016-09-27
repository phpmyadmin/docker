#!/bin/sh
if [ ! -f /www/config.secret.inc.php ] ; then
    cat > /www/config.secret.inc.php <<EOT
<?php
\$cfg['blowfish_secret'] = '`cat /dev/urandom | tr -dc 'a-zA-Z0-9~!@#$%^&*_()+}{?></";.,[]=-' | fold -w 32 | head -n 1`';
EOT
fi

if [ ! -f /config.user.inc.php ] ; then
  touch /config.user.inc.php
fi

mkdir -p /var/nginx/client_body_temp
chown nobody:nobody /sessions /var/nginx/client_body_temp
mkdir -p /var/run/php/
chown nobody:nobody /var/run/php/
touch /var/log/php7.0-fpm.log
chown nobody:nobody /var/log/php7.0-fpm.log

if [ "$1" = 'phpmyadmin' ]; then
    exec supervisord --nodaemon --configuration="/etc/supervisord.conf" --loglevel=info
fi
