FROM alpine

RUN apk add --update php-cli php-mysqli php-ctype php-xml php-gd php-zlib php-openssl php-curl php-opcache php-json \
 && rm -rf /var/cache/apk/*

RUN wget --progress=dot:mega https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz \
 && tar xzf phpMyAdmin*.tar.gz \
 && rm phpMyAdmin*.tar.gz \
 && mv phpMyAdmin* /www

COPY config.inc.arbitrary.php /www/config.inc.arbitrary.php
COPY config.inc.linked.php /www/config.inc.linked.php
COPY run.sh /run.sh
RUN chmod u+rwx /run.sh

EXPOSE 8080

ENTRYPOINT [ "/run.sh" ]
