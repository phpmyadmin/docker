<?php

require('./config.secret.inc.php');

/* Arbitrary server connection */
if (isset($_ENV['PMA_ARBITRARY']) && $_ENV['PMA_ARBITRARY'] === '1') {
    $cfg['AllowArbitraryServer'] = true;
}

/* First server */
$i = 0;
$i++;
$cfg['Servers'][$i]['auth_type'] = 'cookie';
if (isset($_ENV['PMA_HOST'])) {
    $cfg['Servers'][$i]['host'] = $_ENV['PMA_HOST'];
} else {
    $cfg['Servers'][$i]['host'] = 'db';
}
if (isset($_ENV['PMA_PORT'])) {
    $cfg['Servers'][$i]['port'] = $_ENV['PMA_PORT'];
}
$cfg['Servers'][$i]['connect_type'] = 'tcp';
$cfg['Servers'][$i]['compress'] = false;
$cfg['Servers'][$i]['AllowNoPassword'] = true;
$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';
