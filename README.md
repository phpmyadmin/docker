# alpine linux + php + phpmyadmin

Run PHPMyAdmin with alpine + php built in web server

[![Build Status](https://travis-ci.org/phpmyadmin/docker.svg?branch=master)](https://travis-ci.org/phpmyadmin/docker)


## Usage

First， you need to run mysql in docker, and this image need link a running mysql instance container

```
docker run --name myadmin -d --link mysql_db_server:db -p 8080:8080 phpmyadmin/phpmyadmin
```

Then open browser, visit http://***.***.host.ip:8080

You will see the phpmyadmin login page

## Usage with arbitrary server

You can use arbitrary servers by adding ENV variable PMA_ARBITRARY=1 to the startup command:

```
docker run --name myadmin -d --link mysql_db_server:db -p 8080:8080 -e PMA_ARBITRARY=1 phpmyadmin/phpmyadmin
```
