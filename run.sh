#!/bin/sh

# Set Supervisor default config (run tests or not)
if [ "$PHPMYADMIN_RUN_TEST" = true ] ; then
    CONFIG_PATH="/etc/supervisord.test.conf"
else
    CONFIG_PATH="/etc/supervisord.conf"
fi

if [ ! -f /etc/phpmyadmin/config.secret.inc.php ] ; then
    cat > /etc/phpmyadmin/config.secret.inc.php <<EOT
<?php
\$cfg['blowfish_secret'] = '$(tr -dc 'a-zA-Z0-9~!@#$%^&*_()+}{?></";.,[]=-' < /dev/urandom | fold -w 32 | head -n 1)';
EOT
fi

if [ ! -f /etc/phpmyadmin/config.user.inc.php ] ; then
  touch /etc/phpmyadmin/config.user.inc.php
fi

mkdir -p /var/nginx/client_body_temp
chown nobody:nobody /sessions /var/nginx/client_body_temp
mkdir -p /var/run/php/
chown nobody:nobody /var/run/php/
touch /var/log/php-fpm.log
chown nobody:nobody /var/log/php-fpm.log

if [ "$1" = 'phpmyadmin' ]; then
    exec supervisord --nodaemon --configuration=$CONFIG_PATH --loglevel=info
fi
