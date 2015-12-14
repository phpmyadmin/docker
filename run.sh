#!/bin/sh
set -x

if [ ! -f /www/config.secret.inc.php ] ; then
    cat > /www/config.secret.inc.php <<EOT
<?php
\$cfg['blowfish_secret'] = '`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`';
EOT
fi

php -S 0.0.0.0:8080 -t /www/
