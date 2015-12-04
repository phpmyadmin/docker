#!/bin/sh
set -x

# use arbitrary server
if [ "$PMA_ARBITRARY" ]
  then
    cp /www/config.inc.arbitrary.php /www/config.inc.php
  else
    cp /www/config.inc.linked.php /www/config.inc.php
fi

php -S 0.0.0.0:8080 -t /www/
