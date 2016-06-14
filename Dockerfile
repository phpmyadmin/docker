FROM alpine:latest

RUN apk add --no-cache php7-cli php7-mysqli php7-ctype php7-xml php7-gd php7-zlib php7-bz2 php7-zip php7-openssl php7-curl php7-opcache php7-json curl

RUN curl --location https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz | tar xzf - \
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
