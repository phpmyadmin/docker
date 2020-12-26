# Official phpMyAdmin Docker image

Run phpMyAdmin with Alpine, Apache and PHP FPM.

[![GitHub CI build status badge](https://github.com/phpmyadmin/docker/workflows/GitHub%20CI/badge.svg)](https://github.com/phpmyadmin/docker/actions?query=workflow%3A%22GitHub+CI%22)
[![update.sh build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/update.sh/job/phpmyadmin.svg?label=Automated%20update.sh)](https://doi-janky.infosiftr.net/job/update.sh/job/phpmyadmin/)
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

phpMyAdmin connects using your MySQL server credentials. Please check the corresponding
database server image for information on what the default username and password are.
To modify username and password during installation you can check the corresponding
database server image on Docker Hub.

The official MySQL and MariaDB use the following environment variables to define these:

* `MYSQL_ROOT_PASSWORD` - This variable is mandatory and specifies the password that will be set for the `root` superuser account.
* `MYSQL_USER`, `MYSQL_PASSWORD` - These variables are optional, used in conjunction to create a new user and to set that user's password.

## Supported Docker Hub tags

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

First you need to run a MySQL or MariaDB server in Docker, and the phpMyAdmin image needs to be
linked to the running database container:

```sh
docker run --name myadmin -d --link mysql_db_server:db -p 8080:80 phpmyadmin
```

## Usage with external server

You can specify a MySQL host in the `PMA_HOST` environment variable. You can also
use `PMA_PORT` to specify port of the server in case it's not the default one:

```sh
docker run --name myadmin -d -e PMA_HOST=dbhost -p 8080:80 phpmyadmin
```

## Usage with arbitrary server

You can use arbitrary servers by adding ENV variable `PMA_ARBITRARY=1` to the startup command:

```sh
docker run --name myadmin -d -e PMA_ARBITRARY=1 -p 8080:80 phpmyadmin
```

## Usage with docker-compose and arbitrary server

This will run phpMyAdmin with arbitrary server - allowing you to specify MySQL/MariaDB
server on login page.

Using the docker-compose.yml from https://github.com/phpmyadmin/docker

```sh
docker-compose up -d
```

## Run the E2E tests with docker-compose

You can run the E2E tests with the local test environment by running MariaDB/MySQL databases. Adding ENV variable `PHPMYADMIN_RUN_TEST=true` already added on docker-compose file. Simply run:

Using the docker-compose.testing.yml from https://github.com/phpmyadmin/docker

```sh
docker-compose -f docker-compose.testing.yml up phpmyadmin
```

## Adding Custom Configuration

You can add your own custom config.inc.php settings (such as Configuration Storage setup)
 by creating a file named "config.user.inc.php" with the various user defined settings
in it, and then linking it into the container using:

```sh
-v /some/local/directory/config.user.inc.php:/etc/phpmyadmin/config.user.inc.php
```

On the "docker run" line like this:

```sh
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
* ``HIDE_PHP_VERSION`` - if defined, this option will hide the PHP version (`expose_php = Off`). Set to any value (such as `HIDE_PHP_VERSION=true`).
* ``UPLOAD_LIMIT`` - if set, this option will override the default value for apache and php-fpm (format as `[0-9+](K,M,G)` default value is 2048K, this will change ``upload_max_filesize`` and ``post_max_size`` values)
* ``MAX_EXECUTION_TIME`` - if set, will override the maximum execution time in seconds (default 600) for phpMyAdmin ([$cfg['ExecTimeLimit']](https://docs.phpmyadmin.net/en/latest/config.html#cfg_ExecTimeLimit)) and PHP [max_execution_time](https://www.php.net/manual/en/info.configuration.php#ini.max-execution-time) (format as `[0-9+]`)
* ``PMA_CONFIG_BASE64`` - if set, this option will override the default `config.inc.php` with the base64 decoded contents of the variable
* ``PMA_USER_CONFIG_BASE64`` - if set, this option will override the default `config.user.inc.php` with the base64 decoded contents of the variable
* ``PMA_ABSOLUTE_URI`` - the full URL to phpMyAdmin. Sometimes needed when used in a reverse-proxy configuration. Don't set this unless needed. See [documentation](https://docs.phpmyadmin.net/en/latest/config.html#cfg_PmaAbsoluteUri).
* ``PMA_CONTROLHOST`` - when set, this points to an alternate database host used for storing the [phpMyAdmin Configuration Storage database](https://docs.phpmyadmin.net/en/latest/setup.html#phpmyadmin-configuration-storage) database
* ``PMA_CONTROLPORT`` - if set, will override the default port (3306) for connecting to the control host for storing the [phpMyAdmin Configuration Storage database](https://docs.phpmyadmin.net/en/latest/setup.html#phpmyadmin-configuration-storage) database
* ``PMA_PMADB`` - define the name of the database to be used for the [phpMyAdmin Configuration Storage database](https://docs.phpmyadmin.net/en/latest/setup.html#phpmyadmin-configuration-storage). When not set, the advanced features are not enabled by default (they can still potentially be enabled by the user when logging in with the zero conf (zero configuration) feature. Suggested values: `phpmyadmin` or `pmadb`
* ``PMA_CONTROLUSER`` - define the username for phpMyAdmin to use for advanced features (the [controluser](https://docs.phpmyadmin.net/en/latest/config.html#cfg_Servers_controluser))
* ``PMA_CONTROLPASS`` - define the password for phpMyAdmin to use with the [controluser](https://docs.phpmyadmin.net/en/latest/config.html#cfg_Servers_controlpass)
* ``PMA_QUERYHISTORYDB`` - when set [to true](https://docs.phpmyadmin.net/en/latest/config.html#cfg_QueryHistoryDB), enables storing [SQL history](https://docs.phpmyadmin.net/en/latest/config.html#cfg_Servers_history) to the [phpMyAdmin Configuration Storage database](https://docs.phpmyadmin.net/en/latest/setup.html#phpmyadmin-configuration-storage). When [false](https://docs.phpmyadmin.net/en/latest/config.html#cfg_QueryHistoryDB), history is stored in the browser and is cleared when logging out
* ``PMA_QUERYHISTORYMAX`` - when set to an integer, controls the number of history items. See [documentation](https://docs.phpmyadmin.net/en/latest/config.html#cfg_QueryHistoryMax). Defaults to `25`.

For usage with Docker secrets, appending ``_FILE`` to the ``PMA_PASSWORD`` environment variable is allowed (it overrides ``PMA_PASSWORD`` if it is set):

```sh
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
