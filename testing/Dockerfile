# Testing image for phpMyAdmin

FROM alpine:3.12

# Install test dependencies
RUN set -ex; \
	\
	apk add --no-cache --update mariadb-client bash \
	py3-html5lib py3-pytest py3-mechanize
