#!/bin/sh
set -x

# use arbitrary server
if [ "$PMA_ARBITRARY" ]
  then
    cp /www/config.inc.arbitrary.php /www/config.inc.php
  else
    cp /www/config.inc.linked.php /www/config.inc.php
fi

if [ ! -f /www/config.secret.inc.php ] ; then
    cat > /www/config.secret.inc.php <<EOT
<?php
\$cfg['blowfish_secret'] = '`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`';
EOT
fi

php -S 0.0.0.0:8080 -t /www/
