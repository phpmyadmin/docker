# Official phpMyAdmin Docker image

Run phpMyAdmin with Alpine and PHP built in web server.

[![Build Status](https://travis-ci.org/phpmyadmin/docker.svg?branch=master)](https://travis-ci.org/phpmyadmin/docker)


## Usage

First you need to run MySQL or MariaDB server in Docker, and this image need
link a running mysql instance container:

```
docker run --name myadmin -d --link mysql_db_server:db -p 8080:8080 phpmyadmin/phpmyadmin
```

Then open browser, visit http://***.***.host.ip:8080

You will see the phpMyAdmin login page.

## Usage with arbitrary server

You can use arbitrary servers by adding ENV variable PMA\_ARBITRARY=1 to the startup command:

```
docker run --name myadmin -d --link mysql_db_server:db -p 8080:8080 -e PMA_ARBITRARY=1 phpmyadmin/phpmyadmin
```

## Usage with docker-compose and arbitrary server

This will run phpMyAdmin with arbitrary server - allowing you to specify MySQL/MariaDB
server on login page.

Using the docker-compose.yml from https://github.com/phpmyadmin/docker

```
docker-compose up -d
```

than as usual, open http://localhost:8080 and enjoy your happy MySQL administration.
