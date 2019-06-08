FROM php:7.2-%%VARIANT%%

# Install dependencies
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libbz2-dev \
		libfreetype6-dev \
		libjpeg-dev \
		libpng-dev \
		libwebp-dev \
		libxpm-dev \
	; \
	\
	docker-php-ext-configure gd --with-freetype-dir=/usr --with-jpeg-dir=/usr --with-webp-dir=/usr --with-png-dir=/usr --with-xpm-dir=/usr; \
	docker-php-ext-install bz2 gd mysqli opcache zip; \
	\
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

# Calculate download URL
ENV VERSION %%VERSION%%
ENV URL https://files.phpmyadmin.net/phpMyAdmin/${VERSION}/phpMyAdmin-${VERSION}-all-languages.tar.xz
LABEL version=$VERSION

# Download tarball, verify it using gpg and extract
RUN set -ex; \
    fetchDeps=" \
        gnupg \
        dirmngr \
    "; \
    apt-get update; \
    apt-get install -y --no-install-recommends $fetchDeps; \
    \
    export GNUPGHOME="$(mktemp -d)"; \
    export GPGKEY="3D06A59ECE730EB71B511C17CE752F178259BD92"; \
    curl --output phpMyAdmin.tar.xz --location $URL; \
    curl --output phpMyAdmin.tar.xz.asc --location $URL.asc; \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPGKEY" \
        || gpg --batch --keyserver ipv4.pool.sks-keyservers.net --recv-keys "$GPGKEY" \
        || gpg --batch --keyserver keys.gnupg.net --recv-keys "$GPGKEY" \
        || gpg --batch --keyserver pgp.mit.edu --recv-keys "$GPGKEY" \
        || gpg --batch --keyserver keyserver.pgp.com --recv-keys "$GPGKEY"; \
    gpg --batch --verify phpMyAdmin.tar.xz.asc phpMyAdmin.tar.xz; \
    tar -xf phpMyAdmin.tar.xz -C /usr/src; \
    gpgconf --kill all; \
    rm -r "$GNUPGHOME" phpMyAdmin.tar.xz phpMyAdmin.tar.xz.asc; \
    mv /usr/src/phpMyAdmin-$VERSION-all-languages /usr/src/phpmyadmin; \
    rm -rf /usr/src/phpmyadmin/setup/ /usr/src/phpmyadmin/examples/ /usr/src/phpmyadmin/test/ /usr/src/phpmyadmin/po/ /usr/src/phpmyadmin/composer.json /usr/src/phpmyadmin/RELEASE-DATE-$VERSION; \
    sed -i "s@define('CONFIG_DIR'.*@define('CONFIG_DIR', '/etc/phpmyadmin/');@" /usr/src/phpmyadmin/libraries/vendor_config.php; \
# Add directory for sessions to allow session persistence
    mkdir /sessions; \
    mkdir -p /var/nginx/client_body_temp; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $fetchDeps; \
    rm -rf /var/lib/apt/lists/*

# Copy configuration
COPY config.inc.php /etc/phpmyadmin/config.inc.php
COPY php.ini /usr/local/etc/php/conf.d/php-phpmyadmin.ini

# Copy main script
COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["%%CMD%%"]
