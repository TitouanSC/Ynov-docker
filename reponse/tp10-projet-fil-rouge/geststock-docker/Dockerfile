# syntax=docker/dockerfile:1.7
# Choix : php:8.3-apache (un seul conteneur, simple) vs nginx+fpm (2 conteneurs, plus isolé).
# Ici apache intégré pour limiter la surface ops legacy → conteneurs.
FROM php:8.3-apache-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/* \
 && docker-php-ext-install pdo pdo_mysql \
 && a2enmod rewrite \
 && sed -i 's!/var/www/html!/var/www/app/public!g' /etc/apache2/sites-available/000-default.conf \
 && printf '\nAlias /uploads /var/www/uploads\n<Directory /var/www/uploads>\n  Require all granted\n</Directory>\n' \
      >> /etc/apache2/sites-available/000-default.conf \
 && printf 'display_errors=Off\nupload_max_filesize=20M\npost_max_size=25M\nlog_errors=On\nerror_log=/dev/stderr\n' \
      > /usr/local/etc/php/conf.d/geststock.ini \
 && mkdir -p /var/www/uploads \
 && chown -R www-data:www-data /var/www/uploads

WORKDIR /var/www/app
COPY app/ /var/www/app/
RUN chown -R www-data:www-data /var/www/app

# Apache master reste root puis drop workers → www-data (contrainte image officielle)
EXPOSE 80
HEALTHCHECK --interval=10s --timeout=3s --start-period=20s --retries=5 \
  CMD curl -fsS "http://127.0.0.1/?health" | grep -q OK || exit 1

LABEL org.opencontainers.image.title="geststock" \
      org.opencontainers.image.description="GestStock inventaire conteneurisé" \
      org.opencontainers.image.source="https://github.com/TitouanSC/Ynov-docker" \
      org.opencontainers.image.version="2.3.0"

CMD ["apache2-foreground"]
