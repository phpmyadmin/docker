FROM alpine:latest

# Install dependencies
RUN apk add --no-cache php5-cli php5-mysqli php5-ctype php5-xml php5-gd php5-zlib php5-bz2 php5-zip php5-openssl php5-curl php5-opcache php5-json

# Include keyring to verify download
COPY phpmyadmin.keyring /

# Calculate download URL
ENV VERSION 4.6.4
ENV URL https://files.phpmyadmin.net/phpMyAdmin/${VERSION}/phpMyAdmin-${VERSION}-all-languages.tar.gz

# Download tarball, verify it using gpg and extract
RUN set -x \
    && export GNUPGHOME="$(mktemp -d)" \
    && apk add --no-cache curl gnupg \
    && curl --output phpMyAdmin.tar.gz --location $URL \
    && curl --output phpMyAdmin.tar.gz.asc --location $URL.asc \
    && gpgv --keyring /phpmyadmin.keyring phpMyAdmin.tar.gz.asc phpMyAdmin.tar.gz \
    && apk del --no-cache curl gnupg \
    && rm -rf "$GNUPGHOME" \
    && tar xzf phpMyAdmin.tar.gz \
    && rm -f phpMyAdmin.tar.gz phpMyAdmin.tar.gz.asc \
    && mv phpMyAdmin* /www \
    && rm -rf /www/js/jquery/src/ /www/examples /www/po/

# Copy configuration
COPY config.inc.php /www/

# Copy main script
COPY run.sh /run.sh
RUN chmod u+rwx /run.sh

# Add volume for sessions to allow session persistence
VOLUME /sessions

# We expose phpMyAdmin on port 80
EXPOSE 80

# Configure some PHP limits
ENV PHP_UPLOAD_MAX_FILESIZE=64M \
    PHP_MAX_INPUT_VARS=2000

ENTRYPOINT [ "/run.sh" ]
