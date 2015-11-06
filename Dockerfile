FROM netroby/alpine-php

RUN wget --no-check-certificate -c https://github.com/phpmyadmin/phpmyadmin/archive/RELEASE_4_5_1.tar.gz; \
        tar zxvf RELEASE_4_5_1.tar.gz;\
        mv phpmyadmin-RELEASE_4_5_1 /www; \
        unlink *.tar.gz

COPY config.inc.php /www/config.inc.php

EXPOSE 8080

ENTRYPOINT ["php", "-S", "0.0.0.0:8080", "-t", "/www/"]
