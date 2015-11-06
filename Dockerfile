FROM netroby/alpine-php

VOLUME /www
RUN   wget -c https://github.com/phpmyadmin/phpmyadmin/archive/RELEASE_4_5_1.tar.gz; \
        tar zxvf phpmyadmin-RELEASE_4_5_1.tar.gz;\
        mv phpmyadmin-RELEASE_4_5_1 /www; \
        unlink *.tar.gz

COPY config.inc.php /www/config.inc.php

ENV HOME /root

EXPOSE 8080

WORKDIR /root

ENTRYPOINT ["php", "-S", "0.0.0.0:8080", "-t", "/www/"]
