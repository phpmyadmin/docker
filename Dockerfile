FROM alpine

RUN apk add --update php-cli php-mysqli php-ctype php-xml php-gd php-zlib php-openssl php-curl php-opcache php-json curl \
 && rm -rf /var/cache/apk/*

RUN curl --location https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz | tar xzf - \
 && mv phpMyAdmin* /www \
 && rm -rf /www/js/jquery/src/ /www/examples /www/po/

COPY config.inc.php /www/
COPY run.sh /run.sh
RUN chmod u+rwx /run.sh

RUN sed -i \
    -e "s/^upload_max_filesize\s*=\s*2M/upload_max_filesize = 64M/" \
    -e "s/^post_max_size\s*=\s*8M/post_max_size = 64M/" \
    /etc/php/php.ini

EXPOSE 8080

ENTRYPOINT [ "/run.sh" ]
