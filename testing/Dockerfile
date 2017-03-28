# Testing image for phpMyAdmin

FROM phpmyadmin/phpmyadmin

# Install test dependencies
RUN apk add --no-cache curl py2-pip
RUN pip install mechanize html5lib

COPY test-mariadb.ini test-mysql.ini /etc/supervisor.d/
COPY phpmyadmin_test.py test-docker.sh world.sql /
