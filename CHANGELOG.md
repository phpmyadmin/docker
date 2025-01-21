# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [5.2.2] - 2025-01-21

- Add `TZ` env var to change PHP `date.timezone` (#133)
- Update to PHP 8.2 (#411)
- Add back a `/sessions` volume for sessions persistence (#399)
- Support adding custom configurations in `/etc/phpmyadmin/conf.d` (#401)
- Fix for Debian 12 issue (#416) that caused libraries for extensions to be uninstalled
- Add extension `bcmath` for 2nd factor authentication (#415)
- Refactor `update.sh` (#408)
- Enable remoteip mod for Apache (#434)
- Add support for `PMA_SSL` and `PMA_SSLS` to enable SSL connection (#441)
- Fixed looping through `$sockets` using the same index variable `$i` interferes with the last server id (#186)
- Add support for `PMA_SSL_VERIFY` and `PMA_SSL_VERIFIES` (#448)
- Add support for `PMA_SSL_CA` and `PMA_SSL_CAS` (#448)
- Add support for `PMA_SSL_CERT` and `PMA_SSL_CERTS` (#448)
- Add support for `PMA_SSL_KEY` and `PMA_SSL_KEYS` (#448)
- Also add `PMA_SSL_DIR` to define the dir where SSL files are generated for `_BASE64` prefixed variables
- Support `PMA_SSL_CA_BASE64` and `PMA_SSL_CAS_BASE64` as variables that contain the file contents (#448)
- Support `PMA_SSL_KEY_BASE64` and `PMA_SSL_KEYS_BASE64` as variables that contain the file contents (#448)
- Support `PMA_SSL_CERT_BASE64` and `PMA_SSL_CERTS_BASE64` as variables that contain the file contents (#448)

## [5.2.1] - 2023-02-08

- Move docker-compose test files into a folder
- Fix the section about E2E tests in `README.md`
- Support docker secrets from file for `PMA_USER` (#372)
- Support docker secrets from file for `PMA_CONTROLUSER` (#372)
- Support docker secrets from file for `PMA_CONTROLHOST` (#372)
- Allow a different Apache port with `APACHE_PORT` (#340)
- Add support for ENVs `PMA_UPLOADDIR` and `PMA_SAVEDIR` (#384)
- Fixed a bug with `APACHE_PORT` ENV on container restart (#381)
- Update to PHP 8.1 (#393)
- Add support for ENV `TZ`

## [5.1.4] - 2022-05-11

- Fix incorrect image tag name in `README.md`

## [5.1.2] - 2022-01-22

- Fix GPG keyservers in Dockerfiles
- Remove microbadger badges, it closed
- Improve the README file
- Fix add back composer.json and remove non needed source files (#345)
- Update to PHP 8.0 (#325)

## [5.1.1] - 2021-06-04

- Improve documentation

## [5.1.0] - 2021-02-24

- Set ini setting `max_input_vars = 10000`
- Add support for ENV `PMA_QUERYHISTORYMAX`
- Add support for ENV `MAX_EXECUTION_TIME`
- Add support for ENV `MEMORY_LIMIT`
- Move to GitHub actions
- Re-work the test system
- Support docker secrets from file for `PMA_CONTROLPASS`
- Generate phpmyadmin-misc.ini from ENVs

## [4.9.{6,7}] - 2020-10-{10,16} and [5.0.{3,4}] - 2020-10-{10,16}

- Add `tzdata` package
- Extract downloaded files directly to web root `/var/www/html/` (#277)
- Add SHA checksum when downloading a version
- Improved `UPLOAD_LIMIT` documentation
- Update documentation from `phpmyadmin/phpmyadmin` to `phpmyadmin`
- `phpmyadmin` is now the official image in the Docker official library

## [5.0.2] - 2020-03-21

- Add org.opencontainers.image.* labels
- Apply some feedback from docker-library team to Dockerfiles

## [4.9.3] - 2020-01-02 and [5.0.0] - 2019-12-26

- Add support for ENV `HIDE_PHP_VERSION` to set ini setting `expose_php = Off`
- Add support for ENV `UPLOAD_LIMIT` to set `upload_max_filesize` and `post_max_size` ini settings
- Add support for ENVs `PMA_CONFIG_BASE64` and `PMA_USER_CONFIG_BASE64` (#192)
- Support docker secrets from files for `PMA_PASSWORD`, `MYSQL_ROOT_PASSWORD` and `MYSQL_PASSWORD`
- Support docker secrets from files for `PMA_HOSTS` and `PMA_HOST`

## [4.9.2-2] - 2020-12-20

- Update to PHP 7.4 (#257)
- Drop ini setting `opcache.enable_cli=1`
