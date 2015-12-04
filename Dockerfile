FROM netroby/alpine-php

RUN wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz \
 && tar xzf phpMyAdmin*.tar.gz \
 && rm phpMyAdmin*.tar.gz \
 && mv phpMyAdmin* /www

COPY config.inc.php /www/config.inc.php

EXPOSE 8080

ENTRYPOINT ["php", "-S", "0.0.0.0:8080", "-t", "/www/"]

CMD []
