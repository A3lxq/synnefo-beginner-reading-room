FROM php:8.2-apache

RUN apt-get update -qq && apt-get install -y --no-install-recommends -qq \
        sqlite3 libsqlite3-dev steghide \
        zlib1g-dev libpng-dev libjpeg62-turbo-dev \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install pdo_sqlite gd \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite

COPY docker/web/ /var/www/html/
COPY docker/db/schema.sql /opt/schema.sql
COPY docker/db/seed.php /opt/db/seed.php
COPY docker/generate_flags.php /opt/generate_flags.php
COPY docker/make_covers.php /opt/make_covers.php
COPY docker/entrypoint.sh /opt/entrypoint.sh

RUN chmod +x /opt/entrypoint.sh && \
    mkdir -p /var/www/html/data /var/www/html/backup /var/www/html/uploads /var/www/html/images

EXPOSE 80

ENTRYPOINT ["/opt/entrypoint.sh"]
