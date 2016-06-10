#!/bin/sh
set -x

if [ ! -f /www/config.secret.inc.php ] ; then
    cat > /www/config.secret.inc.php <<EOT
<?php
\$cfg['blowfish_secret'] = '`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`';
EOT
fi

exec php -S 0.0.0.0:80 -t /www/ \
    -d upload_max_filesize=$PHP_UPLOAD_MAX_FILESIZE \
    -d post_max_size=$PHP_UPLOAD_MAX_FILESIZE \
    -d max_input_vars=$PHP_MAX_INPUT_VARS \
    -d session.save_path=/sessions
