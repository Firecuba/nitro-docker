FROM php:8.2-apache

RUN docker-php-ext-install pdo pdo_mysql

WORKDIR /var/www/html

# xKiwiRetro/Arcturus-Catalog-Panel -- visual drag & drop catalog editor for
# Arcturus/Morningstar. Pinned commit for reproducible builds; bump manually
# after checking the upstream changelog.
ARG COMMIT=main
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates \
    && git config --global --add safe.directory /var/www/html \
    && git clone https://github.com/xKiwiRetro/Arcturus-Catalog-Panel.git . \
    && git checkout $COMMIT \
    && rm -rf .git \
    && apt-get purge -y git && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

# config.php is generated from environment variables at container start (see
# entrypoint.sh) rather than baked into the image, so the real DB password
# never ends up in an image layer.
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
