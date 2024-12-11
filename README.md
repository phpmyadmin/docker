# Official phpMyAdmin Docker image

Note that since phpMyAdmin has been accepted in to the [official DockerHub repository](https://hub.docker.com/_/phpmyadmin), you can use
either that or this older [phpMyAdmin repository](https://hub.docker.com/r/phpmyadmin/phpmyadmin/) for your Docker installation. This
is maintained as a courtesy to users who have not migrated.

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

All of the following examples will bring you phpMyAdmin on `http://localhost:8080`
where you can enjoy your happy MySQL administration.

## Credentials

phpMyAdmin connects using your MySQL server credentials. Please check your corresponding
database server image for information on the default username and password or how to specify your own custom credentials during installation.

The official MySQL and MariaDB images use the following environment variables to define these:

* `MYSQL_ROOT_PASSWORD` - This variable is mandatory and specifies the password that will be set for the `root` superuser account.
* `MYSQL_USER`, `MYSQL_PASSWORD` - These variables are optional, used in conjunction to create a new user and to set that user's password.

## Supported Docker Hub tags

The following tags are available:

* `latest`, `fpm`, and `fpm-alpine` are always the most recent released version
* Major versions, such as `5`, `5-fpm`, and `5-fpm-alpine`
* Specific minor versions, such as `5.0`, `5.0-fpm`, and `5-fpm-alpine`
* Specific patch versions, such as `5.0.0`, `5.0.0-fpm`, and `5.0.0-fpm-alpine`.  Note that, on rare occasion, there may be an intermediary "docker-only" release, such as 4.9.2-1

A complete list of tags is [available at Docker Hub](https://hub.docker.com/_/phpmyadmin?tab=tags)

## Image variants

We provide three variations:

* "apache" includes a full Apache webserver with PHP and includes everything needed to work out of the box.
This is the default when only a version number is requested.
* "fpm" only starts a PHP FPM container. Use this variant if you already have a separate webserver.
This includes more tools and is therefore a larger image than the "fpm-alpine" variation.
* "fpm-alpine" has a very small footprint. It is based on Alpine Linux and only starts a PHP FPM process.
Use this variant if you already have a separate webserver. If you need more tools that are not available on Alpine Linux, use the fpm image instead.

## Usage with linked server

First you need to run a MySQL or MariaDB server in Docker, and the phpMyAdmin image needs to be
linked to the running database container:

```sh
docker run --name phpmyadmin -d --link mysql_db_server:db -p 8080:80 phpmyadmin:latest
```

## Usage with external server

You can specify a MySQL host in the `PMA_HOST` environment variable. You can also
use `PMA_PORT` to specify the port of the server in case it's not the default one:

```sh
docker run --name phpmyadmin -d -e PMA_HOST=dbhost -p 8080:80 phpmyadmin:latest
```

## Usage with arbitrary server

You can use arbitrary servers by adding the environment variable `PMA_ARBITRARY=1` to the startup command:

```sh
docker run --name phpmyadmin -d -e PMA_ARBITRARY=1 -p 8080:80 phpmyadmin:latest
```

## Usage with docker compose and an arbitrary server

This will run phpMyAdmin with the arbitrary server option - allowing you to specify any MySQL/MariaDB
server on the login page.

```yaml
version: '3.1'

services:
  db:
    image: mariadb:10.11
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: notSecureChangeMe

  phpmyadmin:
    image: phpmyadmin
    restart: always
    ports:
      - 8080:80
    environment:
      - PMA_ARBITRARY=1
```

## Adding Custom Configuration

You can add your own custom config.inc.php settings (such as Configuration Storage setup)
 by creating a file named `config.user.inc.php` with the various user defined settings
in it, and then linking it into the container using:

```sh
-v /some/local/directory/config.user.inc.php:/etc/phpmyadmin/config.user.inc.php
```

On the `docker run` line like this:

```sh
docker run --name phpmyadmin -d --link mysql_db_server:db -p 8080:80 -v /some/local/directory/config.user.inc.php:/etc/phpmyadmin/config.user.inc.php phpmyadmin:latest
```

Be sure to have `<?php` as your first line of the configuration file or the contents will not be detected as PHP code.

Example:

```php
<?php

$cfg['ShowPhpInfo'] = true; // Adds a link to phpinfo() on the home page
```

See the following links for config file information:

* https://docs.phpmyadmin.net/en/latest/config.html#config
* https://docs.phpmyadmin.net/en/latest/setup.html

## Adding custom configuration in `/etc/phpmyadmin/conf.d`

you can also consider storing your custom configuration files in the folder `/etc/phpmyadmin/conf.d`, which is very suitable for managing multiple phpMyAdmin configuration files for different hosts,Then you can create `server-1.php`, `server-2.php`, or any file name you want, and store them in the conf.d directory mounted on the host.

On the `docker run` line like this:

```sh
docker run --name phpmyadmin -d --link mysql_db_server:db -p 8080:80 -v /some/local/directory/conf.d:/etc/phpmyadmin/conf.d:ro phpmyadmin:latest
```

## Usage behind a reverse proxy

Set the variable ``PMA_ABSOLUTE_URI`` to the fully-qualified path (``https://pma.example.net/``) where the reverse proxy makes phpMyAdmin available.

## Sessions persistence

In order to keep your sessions active between container updates you will need to mount the `/sessions` folder.

```sh
-v /some/local/directory/sessions:/sessions:rw
```

## Connect to the database over SSL

Set the variable ``PMA_SSL`` to `1` to enable SSL usage from phpMyAdmin to the MySQL server.
The default value is `0`.
The variable ``PMA_SSLS`` can be used as a comma seperated sequence of `0` and `1` where multiple hosts are mentioned.
Values order must follow the ``PMA_HOSTS`` and will be computed accordingly.

```sh
docker run --name phpmyadmin -d -e PMA_HOSTS=sslhost -e PMA_SSL=1 -p 8080:80 phpmyadmin:latest
```

```sh
docker run --name phpmyadmin -d -e PMA_HOSTS='sslhost,nosslhost' -e PMA_SSLS='1,0' -p 8080:80 phpmyadmin:latest
```

## Environment variables summary

* ``PMA_ARBITRARY`` - when set to 1 connection to the arbitrary server will be allowed
* ``PMA_HOST`` - define address/host name of the MySQL server
* ``PMA_VERBOSE`` - define verbose name of the MySQL server
* ``PMA_PORT`` - define port of the MySQL server
* ``PMA_HOSTS`` - define comma separated list of address/host names of the MySQL servers
* ``PMA_VERBOSES`` - define comma separated list of verbose names of the MySQL servers
* ``PMA_PORTS`` -  define comma separated list of ports of the MySQL servers
* ``PMA_SOCKET`` - define socket file for the MySQL connection
* ``PMA_SOCKETS`` - define comma separated list of socket files for the MySQL connections
* ``PMA_SSL`` - when set to 1, defines SSL usage for the MySQL connection
* ``PMA_SSL_VERIFY`` - when set to 1, enables SSL certificate verification for the MySQL connection.
* ``PMA_SSL_VERIFIES`` - comma-separated list of `0` and `1` to enable or disable SSL certificate verification for multiple MySQL connections.
* ``PMA_SSL_CA_BASE64`` - in the context of mTLS security, allows setting your CA file as a base64 string inside the default `config.inc.php`.
* ``PMA_SSL_CAS_BASE64`` - in the context of mTLS security, allows setting multiple CA files as a comma-separated list of base64 strings inside the default `config.inc.php`.
* ``PMA_SSL_CERT_BASE64`` - in the context of mTLS security, allows setting your CERT file as a base64 string inside the default `config.inc.php`.
* ``PMA_SSL_CERTS_BASE64`` - in the context of mTLS security, allows setting multiple CERT files as a comma-separated list of base64 strings inside the default `config.inc.php`.
* ``PMA_SSL_KEY_BASE64`` - in the context of mTLS security, allows setting your KEY file as a base64 string inside the default `config.inc.php`.
* ``PMA_SSL_KEYS_BASE64`` - in the context of mTLS security, allows setting multiple KEY files as a comma-separated list of base64 strings inside the default `config.inc.php`.
* ``PMA_USER`` and ``PMA_PASSWORD`` - define username and password to use only with the `config` authentication method
* ``PMA_ABSOLUTE_URI`` - the full URL to phpMyAdmin. Sometimes needed when used in a reverse-proxy configuration. Don't set this unless needed. See [documentation](https://docs.phpmyadmin.net/en/latest/config.html#cfg_PmaAbsoluteUri).
* ``PMA_CONFIG_BASE64`` - if set, this option will override the default `config.inc.php` with the base64 decoded contents of the variable
* ``PMA_USER_CONFIG_BASE64`` - if set, this option will override the default `config.user.inc.php` with the base64 decoded contents of the variable
* ``PMA_UPLOADDIR`` - if defined, this option will set the path where files can be saved to be available to import ([$cfg['UploadDir']](https://docs.phpmyadmin.net/en/latest/config.html#cfg_UploadDir))
* ``PMA_SAVEDIR`` - if defined, this option will set the path where exported files can be saved ([$cfg['SaveDir']](https://docs.phpmyadmin.net/en/latest/config.html#cfg_SaveDir))
* ``PMA_CONTROLHOST`` - when set, this points to an alternate database host used for storing the [phpMyAdmin Configuration Storage database](https://docs.phpmyadmin.net/en/latest/setup.html#phpmyadmin-configuration-storage) database
* ``PMA_CONTROLPORT`` - if set, will override the default port (3306) for connecting to the control host for storing the [phpMyAdmin Configuration Storage database](https://docs.phpmyadmin.net/en/latest/setup.html#phpmyadmin-configuration-storage) database
* ``PMA_PMADB`` - define the name of the database to be used for the [phpMyAdmin Configuration Storage database](https://docs.phpmyadmin.net/en/latest/setup.html#phpmyadmin-configuration-storage). When not set, the advanced features are not enabled by default: they can still potentially be enabled by the user when logging in with the zero conf (zero configuration) feature. Suggested values: `phpmyadmin` or `pmadb`
* ``PMA_CONTROLUSER`` - define the username for phpMyAdmin to use for advanced features (the [controluser](https://docs.phpmyadmin.net/en/latest/config.html#cfg_Servers_controluser))
* ``PMA_CONTROLPASS`` - define the password for phpMyAdmin to use with the [controluser](https://docs.phpmyadmin.net/en/latest/config.html#cfg_Servers_controlpass)
* ``PMA_QUERYHISTORYDB`` - when set [to true](https://docs.phpmyadmin.net/en/latest/config.html#cfg_QueryHistoryDB), enables storing [SQL history](https://docs.phpmyadmin.net/en/latest/config.html#cfg_Servers_history) to the [phpMyAdmin Configuration Storage database](https://docs.phpmyadmin.net/en/latest/setup.html#phpmyadmin-configuration-storage). When [false](https://docs.phpmyadmin.net/en/latest/config.html#cfg_QueryHistoryDB), history is stored in the browser and is cleared when logging out
* ``PMA_QUERYHISTORYMAX`` - when set to an integer, controls the number of history items. See [documentation](https://docs.phpmyadmin.net/en/latest/config.html#cfg_QueryHistoryMax). Defaults to `25`.
* ``MAX_EXECUTION_TIME`` - if set, will override the maximum execution time in seconds (default 600) for phpMyAdmin ([$cfg['ExecTimeLimit']](https://docs.phpmyadmin.net/en/latest/config.html#cfg_ExecTimeLimit)) and PHP [max_execution_time](https://www.php.net/manual/en/info.configuration.php#ini.max-execution-time) (format as `[0-9+]`)
* ``MEMORY_LIMIT`` - if set, will override the memory limit (default 512M) for phpMyAdmin ([$cfg['MemoryLimit']](https://docs.phpmyadmin.net/en/latest/config.html#cfg_MemoryLimit)) and PHP [memory_limit](https://www.php.net/manual/en/ini.core.php#ini.memory-limit) (format as `[0-9+](K,M,G)` where K is for Kilobytes, M for Megabytes, G for Gigabytes and 1K = 1024 bytes)
* ``UPLOAD_LIMIT`` - if set, this option will override the default value for apache and php-fpm (format as `[0-9+](K,M,G)` default value is 2048K, this will change ``upload_max_filesize`` and ``post_max_size`` values)
* ``TZ`` - if defined, this option will change the default PHP `date.timezone` from `UTC`. See [documentation](https://www.php.net/manual/en/timezones.php) for supported values.
* ``HIDE_PHP_VERSION`` - if defined, this option will hide the PHP version (`expose_php = Off`). Set to any value (such as `HIDE_PHP_VERSION=true`).
* ``APACHE_PORT`` - if defined, this option will change the default Apache port from `80` in case you want it to run on a different port like an unprivileged port.  Set to any port value (such as `APACHE_PORT=8090`)

For usage with Docker secrets, appending ``_FILE`` to the ``PMA_PASSWORD`` environment variable is allowed (it overrides ``PMA_PASSWORD`` if it is set):

```sh
docker run --name phpmyadmin -d -e PMA_PASSWORD_FILE=/run/secrets/db_password.txt -p 8080:80 phpmyadmin:latest
```

#### Variables that can be read from a file using ``_FILE``

- `MYSQL_ROOT_PASSWORD`
- `MYSQL_PASSWORD`
- `PMA_USER`
- `PMA_PASSWORD`
- `PMA_HOSTS`
- `PMA_HOST`
- `PMA_CONTROLHOST`
- `PMA_CONTROLUSER`
- `PMA_CONTROLPASS`
- `PMA_SSL`
- `PMA_SSLS`

## Run the E2E tests for this docker image

You can run the E2E test suite on a local test environment.
The Requirements are `make`, `docker` and the `docker compose` plugin.

Clone this repository: `https://github.com/phpmyadmin/docker.git`

And then run this command to start the test suite:
```sh
make run-tests
```

For more detailed documentation see https://docs.phpmyadmin.net/en/latest/setup.html#installing-using-docker

[hub]: https://hub.docker.com/_/phpmyadmin

Please report any issues with the Docker container to https://github.com/phpmyadmin/docker/issues

Please report any issues with phpMyAdmin to https://github.com/phpmyadmin/phpmyadmin/issues
