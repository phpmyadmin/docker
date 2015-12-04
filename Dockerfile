FROM netroby/alpine-php

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
