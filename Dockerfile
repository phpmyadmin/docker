FROM netroby/alpine-php

RUN wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
RUN tar xzf phpMyAdmin*.tar.gz
RUN rm xzf phpMyAdmin*.tar.gz
RUN mv phpMyAdmin* /www

COPY config.inc.php /www/config.inc.php

EXPOSE 8080

ENTRYPOINT ["php", "-S", "0.0.0.0:8080", "-t", "/www/"]

CMD []
