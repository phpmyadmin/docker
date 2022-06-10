# Testing image for phpMyAdmin

FROM alpine:3.13

# Install test dependencies
RUN set -ex; \
	\
	apk add --no-cache --update mariadb-client bash \
	py3-html5lib py3-pytest py3-mechanize
