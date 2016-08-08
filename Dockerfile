FROM alpine:latest

RUN apk add --no-cache php5-cli php5-mysqli php5-ctype php5-xml php5-gd php5-zlib php5-bz2 php5-zip php5-openssl php5-curl php5-opcache php5-json

COPY phpmyadmin.keyring /

RUN set -x \
    && export GNUPGHOME="$(mktemp -d)" \
    && apk add --no-cache curl gnupg \
    && curl --output phpMyAdmin-latest-all-languages.tar.gz --location https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz \
    && curl --output phpMyAdmin-latest-all-languages.tar.gz.asc --location https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz.asc \
    && gpgv --keyring /phpmyadmin.keyring phpMyAdmin-latest-all-languages.tar.gz.asc phpMyAdmin-latest-all-languages.tar.gz \
    && apk del curl gnupg \
    && rm -rf "$GNUPGHOME" \
    && tar xzf phpMyAdmin-latest-all-languages.tar.gz \
    && rm -f phpMyAdmin-latest-all-languages.tar.gz phpMyAdmin-latest-all-languages.tar.gz.asc \
    && mv phpMyAdmin* /www \
    && rm -rf /www/js/jquery/src/ /www/examples /www/po/

COPY config.inc.php /www/
COPY run.sh /run.sh
RUN chmod u+rwx /run.sh

VOLUME /sessions

EXPOSE 80

ENV PHP_UPLOAD_MAX_FILESIZE=64M \
    PHP_MAX_INPUT_VARS=2000

ENTRYPOINT [ "/run.sh" ]
