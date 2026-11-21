# DO NOT EDIT: created by update.sh from Dockerfile-debian.template
# Build the release kit from the signed release tag instead of downloading it, so
# that the dependencies are locked for the PHP version of this image and can be
# updated to fix vulnerabilities for the lifetime of the version.
# See https://github.com/phpmyadmin/docker/issues/472
FROM --platform=$BUILDPLATFORM php:8.3-cli-trixie AS phpmyadmin-kit

ENV PMA_VERSION="5.2.3" \
    PMA_BRANCH="QA_5_2" \
    PMA_TAG="RELEASE_5_2_3" \
    PMA_COMMIT="962857e4f63d42e38f11ff4d63f5e722018add76" \
    PMA_GPG_KEY="3D06A59ECE730EB71B511C17CE752F178259BD92" \
    COREPACK_ENABLE_DOWNLOAD_PROMPT="0"

# Official image, so no installer is downloaded from getcomposer.org
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        gettext \
        git \
        gnupg \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libzip-dev \
        make \
        nodejs \
        python3-sphinx \
        xz-utils \
    ; \
    docker-php-ext-install gd mysqli zip; \
    corepack enable; \
    rm -rf /var/lib/apt/lists/*; \
    echo 'memory_limit = 512M' > "$PHP_INI_DIR/conf.d/zz-build.ini"

# The release tag must be signed by the phpMyAdmin release key and point at the
# commit pinned in the generated Dockerfile
RUN set -eux; \
    git init /src; \
    cd /src; \
    git remote add origin https://github.com/phpmyadmin/phpmyadmin.git; \
    git fetch --depth 1 origin "refs/tags/${PMA_TAG}:refs/tags/${PMA_TAG}"; \
    test "$(git rev-parse "${PMA_TAG}^{commit}")" = "$PMA_COMMIT"; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$PMA_GPG_KEY" \
        || gpg --batch --keyserver pgp.mit.edu --recv-keys "$PMA_GPG_KEY" \
        || gpg --batch --keyserver keyserver.pgp.com --recv-keys "$PMA_GPG_KEY" \
        || gpg --batch --keyserver keys.openpgp.org --recv-keys "$PMA_GPG_KEY" \
    ; \
    gpg --batch --with-colons --list-keys "$PMA_GPG_KEY" | grep -q "^fpr:.*:${PMA_GPG_KEY}:"; \
    git verify-tag --raw "$PMA_TAG" > /tmp/verify-tag.log 2>&1; \
    ! grep -qE "REVKEYSIG|EXPKEYSIG|EXPSIG|BADSIG|ERRSIG" /tmp/verify-tag.log; \
    grep -qE "^\[GNUPG:\] VALIDSIG [0-9A-F]+ [0-9-]+ [0-9]+ .*${PMA_GPG_KEY}( |$)" /tmp/verify-tag.log; \
    git checkout -B "$PMA_BRANCH" "$PMA_COMMIT"; \
    gpgconf --kill all; \
    rm -r "$GNUPGHOME"

# create-release.sh locks the dependencies for the minimum PHP version it
# parses out of composer.json, lock them for the one of this image instead
RUN set -eux; \
    cd /src; \
    php_version="$(php -r 'echo PHP_VERSION;')"; \
    sed -i "s|^PHP_REQ=.*|PHP_REQ=\"${php_version}\"|" scripts/create-release.sh; \
    grep -q "^PHP_REQ=\"${php_version}\"$" scripts/create-release.sh; \
    echo y | ./scripts/create-release.sh "$PMA_VERSION" "$PMA_BRANCH" \
        --kits all-languages --compressions txz --no-sign; \
    sha256sum "/src/release/phpMyAdmin-${PMA_VERSION}-all-languages.tar.xz"

# Show the advisories left in the kit that actually ships
RUN set -eux; \
    mkdir -p /kit; \
    tar -xf "/src/release/phpMyAdmin-${PMA_VERSION}-all-languages.tar.xz" -C /kit --strip-components=1; \
    cd /kit; \
    composer --version; \
    composer audit --no-dev --format=table || true

FROM php:8.3-fpm

ENV UPLOAD_PROGRESS_EXT_URL="https://github.com/php/pecl-php-uploadprogress/archive/refs/tags/uploadprogress-2.0.2.tar.gz"
ENV UPLOAD_PROGRESS_SHA256="fe3f6cdfcedad563c970c4fd1cda31e422cfc0df5cc9a217d8c80ed3c8d137f5"

# Install dependencies
RUN set -ex; \
    \
    apt-get update; \
    \
    savedAptMark="$(apt-mark showmanual)"; \
    \
    apt-get install -y --no-install-recommends \
        libbz2-dev \
        libfreetype6-dev \
        libjpeg-dev \
        libpng-dev \
        libwebp-dev \
        libxpm-dev \
        libzip-dev \
    ; \
    \
    mkdir -p /tmp/uploadprogress; \
    curl -fsSL -o /tmp/uploadprogress/uploadprogress.tar.gz "$UPLOAD_PROGRESS_EXT_URL"; \
    echo "$UPLOAD_PROGRESS_SHA256 /tmp/uploadprogress/uploadprogress.tar.gz" | sha256sum -c -; \
    tar -xf /tmp/uploadprogress/uploadprogress.tar.gz -C /tmp/uploadprogress --strip-components=1; \
    \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-xpm; \
    docker-php-ext-install -j "$(nproc)" \
        bz2 \
        gd \
        mysqli \
        opcache \
        zip \
        bcmath \
        /tmp/uploadprogress \
    ; \
    \
    rm -r /tmp/uploadprogress; \
    \
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    extdir="$(php -r 'echo ini_get("extension_dir");')"; \
    ldd "$extdir"/*.so \
        | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); print so }' \
        | sort -u \
        | xargs -r dpkg-query -S \
        | cut -d: -f1 \
        | sort -u \
        | xargs -rt apt-mark manual; \
    \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*; \
    ldd "$extdir"/*.so | grep -qzv "=> not found" || (echo "Sanity check failed: missing libraries:"; ldd "$extdir"/*.so | grep " => not found"; exit 1); \
    ldd "$extdir"/*.so | grep -q "libzip.so.* => .*/libzip.so.*" || (echo "Sanity check failed: libzip.so is not referenced"; ldd "$extdir"/*.so; exit 1); \
    err="$(php --version 3>&1 1>&2 2>&3)"; \
    [ -z "$err" ] || (echo "Sanity check failed: php returned errors; $err"; exit 1;);

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
ENV PMA_SSL_DIR=/etc/phpmyadmin/ssl
ENV MAX_EXECUTION_TIME=600
ENV MEMORY_LIMIT=512M
ENV UPLOAD_LIMIT=2048K
ENV TZ=UTC
ENV SESSION_SAVE_PATH=/sessions
RUN set -ex; \
    mkdir $SESSION_SAVE_PATH; \
    mkdir -p $PMA_SSL_DIR; \
    chmod 1777 $SESSION_SAVE_PATH; \
    chmod 755 $PMA_SSL_DIR; \
    chown www-data:www-data /etc/phpmyadmin; \
    chown www-data:www-data $PMA_SSL_DIR; \
    chown www-data:www-data $SESSION_SAVE_PATH; \
    \
    { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
    } > $PHP_INI_DIR/conf.d/opcache-recommended.ini; \
    \
    { \
        echo 'session.cookie_httponly=1'; \
        echo 'session.use_strict_mode=1'; \
    } > $PHP_INI_DIR/conf.d/session-strict.ini; \
    \
    { \
        echo 'allow_url_fopen=Off'; \
        echo 'max_execution_time=${MAX_EXECUTION_TIME}'; \
        echo 'max_input_vars=10000'; \
        echo 'memory_limit=${MEMORY_LIMIT}'; \
        echo 'post_max_size=${UPLOAD_LIMIT}'; \
        echo 'upload_max_filesize=${UPLOAD_LIMIT}'; \
        echo 'date.timezone=${TZ}'; \
        echo 'session.save_path=${SESSION_SAVE_PATH}'; \
    } > $PHP_INI_DIR/conf.d/phpmyadmin-misc.ini

USER www-data:www-data

# Version of phpMyAdmin built above
ENV VERSION=5.2.3

LABEL org.opencontainers.image.title="Official phpMyAdmin Docker image" \
    org.opencontainers.image.description="Run phpMyAdmin with Alpine, Apache and PHP FPM." \
    org.opencontainers.image.authors="The phpMyAdmin Team <developers@phpmyadmin.net>" \
    org.opencontainers.image.vendor="phpMyAdmin" \
    org.opencontainers.image.documentation="https://github.com/phpmyadmin/docker#readme" \
    org.opencontainers.image.licenses="GPL-2.0-only" \
    org.opencontainers.image.version="${VERSION}" \
    org.opencontainers.image.url="https://github.com/phpmyadmin/docker#readme" \
    org.opencontainers.image.source="https://github.com/phpmyadmin/docker.git"

# Copy the kit built from the signed release tag
COPY --chown=www-data:www-data --from=phpmyadmin-kit /kit/ /var/www/html/

RUN set -ex; \
    mkdir -p /var/www/html/tmp; \
    rm -r -v /var/www/html/setup/ /var/www/html/examples/ /var/www/html/js/src/ /var/www/html/babel.config.json /var/www/html/doc/html/_sources/ /var/www/html/RELEASE-DATE-$VERSION /var/www/html/CONTRIBUTING.md; \
    grep -q -F "'configFile' => ROOT_PATH . 'config.inc.php'," /var/www/html/libraries/vendor_config.php; \
    sed -i "s@'configFile' => .*@'configFile' => '/etc/phpmyadmin/config.inc.php',@" /var/www/html/libraries/vendor_config.php; \
    grep -q -F "'configFile' => '/etc/phpmyadmin/config.inc.php'," /var/www/html/libraries/vendor_config.php; \
    php -l /var/www/html/libraries/vendor_config.php; \
    find /var/www/html -type d -exec chmod 555 {} \;; \
    find /var/www/html -type f -exec chmod 444 {} \;; \
    chmod 1777 /var/www/html/tmp;

# Copy configuration
COPY --chown=www-data:www-data config.inc.php /etc/phpmyadmin/config.inc.php
COPY --chown=www-data:www-data helpers.php /etc/phpmyadmin/helpers.php

# Copy main script
COPY docker-entrypoint.sh /docker-entrypoint.sh

USER root
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["php-fpm"]
