FROM alpine

RUN apk add --update php-cli php-mysqli php-ctype php-xml php-gd php-zlib php-openssl php-curl php-opcache php-json curl \
 && rm -rf /var/cache/apk/*

RUN mkdir /www && cd /www \
 && curl --location https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz | tar xzf - \
 && mv phpMyAdmin*/* . && rmdir phpMyAdmin*

COPY config.inc.arbitrary.php /www/config.inc.arbitrary.php
COPY config.inc.linked.php /www/config.inc.linked.php
COPY run.sh /run.sh
RUN chmod u+rwx /run.sh

EXPOSE 8080

ENTRYPOINT [ "/run.sh" ]
