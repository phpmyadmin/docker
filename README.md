# Official phpMyAdmin Docker image

Run phpMyAdmin with Alpine, Apache and PHP FPM.

[![Build Status Travis](https://travis-ci.org/phpmyadmin/docker.svg?branch=master)](https://travis-ci.org/phpmyadmin/docker)
[![amd64 build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/amd64/job/phpmyadmin.svg?label=amd64)](https://doi-janky.infosiftr.net/job/multiarch/job/amd64/job/phpmyadmin)
[![arm32v5 build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/arm32v5/job/phpmyadmin.svg?label=arm32v5)](https://doi-janky.infosiftr.net/job/multiarch/job/arm32v5/job/phpmyadmin)
[![arm32v6 build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/arm32v6/job/phpmyadmin.svg?label=arm32v6)](https://doi-janky.infosiftr.net/job/multiarch/job/arm32v6/job/phpmyadmin)
[![arm32v7 build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/arm32v7/job/phpmyadmin.svg?label=arm32v7)](https://doi-janky.infosiftr.net/job/multiarch/job/arm32v7/job/phpmyadmin)
[![arm64v8 build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/arm64v8/job/phpmyadmin.svg?label=arm64v8)](https://doi-janky.infosiftr.net/job/multiarch/job/arm64v8/job/phpmyadmin)
[![i386 build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/i386/job/phpmyadmin.svg?label=i386)](https://doi-janky.infosiftr.net/job/multiarch/job/i386/job/phpmyadmin)
[![mips64le build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/mips64le/job/phpmyadmin.svg?label=mips64le)](https://doi-janky.infosiftr.net/job/multiarch/job/mips64le/job/phpmyadmin)
[![ppc64le build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/ppc64le/job/phpmyadmin.svg?label=ppc64le)](https://doi-janky.infosiftr.net/job/multiarch/job/ppc64le/job/phpmyadmin)
[![s390x build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/s390x/job/phpmyadmin.svg?label=s390x)](https://doi-janky.infosiftr.net/job/multiarch/job/s390x/job/phpmyadmin)
[![Docker Pulls](https://img.shields.io/docker/pulls/_/phpmyadmin.svg)][hub]
[![Docker Stars](https://img.shields.io/docker/stars/_/phpmyadmin.svg)][hub]
[![Docker Layers](https://images.microbadger.com/badges/image/phpmyadmin.svg)](https://microbadger.com/images/phpmyadmin "Get your own image badge on microbadger.com")
[![Docker Version](https://images.microbadger.com/badges/version/phpmyadmin.svg)](https://microbadger.com/images/phpmyadmin "Get your own version badge on microbadger.com")


All following examples will bring you phpMyAdmin on `http://localhost:8080`
where you can enjoy your happy MySQL administration.

## Credentials

phpMyAdmin does use MySQL server credential, please check the corresponding
server image for information how it is setup.

The official MySQL and MariaDB use following environment variables to define these:

* `MYSQL_ROOT_PASSWORD` - This variable is mandatory and specifies the password that will be set for the `root` superuser account.
* `MYSQL_USER`, `MYSQL_PASSWORD` - These variables are optional, used in conjunction to create a new user and to set that user's password.

## Supported Docker hub tags

The following tags are available:

* `latest`, `fpm`, and `fpm-alpine` are always the most recent released version
* Major versions, such as `5`, `5-fpm`, and `5-fpm-alpine`
* Specific minor versions, such as `5.0`, `5.0-fpm`, and `5-fpm-alpine`
* Specific patch versions, such as `5.0.0`, `5.0.0-fpm`, and `5.0.0-alpine`

A complete list of tags is [available at Docker Hub](https://hub.docker.com/_/phpmyadmin?tab=tags)

## Image variants

We provide three variations:

* "apache" includes a full Apache webserver with PHP and includes everything needed to work out of the box.
This is the default when only a version number is requested.
* "fpm" only starts a PHP FPM container. Use this variant if you already have a seperate webserver.
This includes more tools and is therefore a larger image than the "fpm-alpine" variation.
* "fpm-alpine" has a very small footprint. It is based on Alpine Linux and only starts a PHP FPM process.
Use this variant if you already have a seperate webserver. If you need more tools that are not available on Alpine Linux, use the fpm image instead.

## Usage with linked server

First you need to run MySQL or MariaDB server in Docker, and this image need
link a running mysql instance container:

```
docker run --name myadmin -d --link mysql_db_server:db -p 8080:80 phpmyadmin
```

## Usage with external server

You can specify MySQL host in the `PMA_HOST` environment variable. You can also
use `PMA_PORT` to specify port of the server in case it's not the default one:

```
docker run --name myadmin -d -e PMA_HOST=dbhost -p 8080:80 phpmyadmin
```

## Usage with arbitrary server

You can use arbitrary servers by adding ENV variable `PMA_ARBITRARY=1` to the startup command:

```
docker run --name myadmin -d -e PMA_ARBITRARY=1 -p 8080:80 phpmyadmin
```

## Usage with docker-compose and arbitrary server

This will run phpMyAdmin with arbitrary server - allowing you to specify MySQL/MariaDB
server on login page.

Using the docker-compose.yml from https://github.com/phpmyadmin/docker

```
docker-compose up -d
```

## Run the E2E tests with docker-compose

You can run the E2E tests with the local test environment by running MariaDB/MySQL databases. Adding ENV variable `PHPMYADMIN_RUN_TEST=true` already added on docker-compose file. Simply run:

Using the docker-compose.testing.yml from https://github.com/phpmyadmin/docker

```
docker-compose -f docker-compose.testing.yml up phpmyadmin
```

## Adding Custom Configuration

You can add your own custom config.inc.php settings (such as Configuration Storage setup)
 by creating a file named "config.user.inc.php" with the various user defined settings
in it, and then linking it into the container using:

```
-v /some/local/directory/config.user.inc.php:/etc/phpmyadmin/config.user.inc.php
```
On the "docker run" line like this:
```
docker run --name myadmin -d --link mysql_db_server:db -p 8080:80 -v /some/local/directory/config.user.inc.php:/etc/phpmyadmin/config.user.inc.php phpmyadmin
```

See the following links for config file information.
https://docs.phpmyadmin.net/en/latest/config.html#config
https://docs.phpmyadmin.net/en/latest/setup.html

## Usage behind reverse proxys

Set the variable ``PMA_ABSOLUTE_URI`` to the fully-qualified path (``https://pma.example.net/``) where the reverse proxy makes phpMyAdmin available.

## Environment variables summary

* ``PMA_ARBITRARY`` - when set to 1 connection to the arbitrary server will be allowed
* ``PMA_HOST`` - define address/host name of the MySQL server
* ``PMA_VERBOSE`` - define verbose name of the MySQL server
* ``PMA_PORT`` - define port of the MySQL server
* ``PMA_HOSTS`` - define comma separated list of address/host names of the MySQL servers
* ``PMA_VERBOSES`` - define comma separated list of verbose names of the MySQL servers
* ``PMA_PORTS`` -  define comma separated list of ports of the MySQL servers
* ``PMA_USER`` and ``PMA_PASSWORD`` - define username to use for config authentication method
* ``PMA_ABSOLUTE_URI`` - define user-facing URI
* ``HIDE_PHP_VERSION`` - if defined, will hide the php version (`expose_php = Off`). Set to any value (such as HIDE_PHP_VERSION=true).
* ``UPLOAD_LIMIT`` - if set, will override the default value for apache and php-fpm (format as `[0-9+](K,M,G)` default value is 2048K, this will change ``upload_max_filesize`` and ``post_max_size`` values)
* ``PMA_CONFIG_BASE64`` - if set, will override the default config.inc.php with the base64 decoded contents of the variable
* ``PMA_USER_CONFIG_BASE64`` - if set, will override the default config.user.inc.php with the base64 decoded contents of the variable

For usage with Docker secrets, appending ``_FILE`` to the ``PMA_PASSWORD`` environment variable is allowed (it overrides ``PMA_PASSWORD`` if it is set):
```
docker run --name myadmin -d -e PMA_PASSWORD_FILE=/run/secrets/db_password.txt -p 8080:80 phpmyadmin
```

#### Variables that can be read from a file using ``_FILE``
- PMA_PASSWORD
- MYSQL_ROOT_PASSWORD
- MYSQL_PASSWORD
- PMA_HOSTS
- PMA_HOST

For more detailed documentation see https://docs.phpmyadmin.net/en/latest/setup.html#installing-using-docker

[hub]: https://hub.docker.com/_/phpmyadmin

Please report any issues with the Docker container to https://github.com/phpmyadmin/docker/issues

Please report any issues with phpMyAdmin to https://github.com/phpmyadmin/phpmyadmin/issues
