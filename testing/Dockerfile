# Testing image for phpMyAdmin

FROM phpmyadmin/phpmyadmin

# Install test dependencies
RUN set -ex; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		curl \
		python-pip \
	; \
	pip install mechanize html5lib; \
	rm -rf /var/lib/apt/lists/*

COPY phpmyadmin_test.py test-docker.sh world.sql /
