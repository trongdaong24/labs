FROM php:8.1-apache

# System deps + PHP extensions Voyager/Laravel need
RUN apt-get update && apt-get install -y \
        git unzip default-mysql-client \
        libzip-dev libpng-dev libonig-dev libxml2-dev libjpeg-dev libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring gd zip exif bcmath \
    && rm -rf /var/lib/apt/lists/*

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Point Apache at Laravel's public/ and enable rewrites
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && a2enmod rewrite

WORKDIR /var/www/html

# Vuln lab: intentionally allow EOL/advisory-flagged packages
RUN composer config --global policy.advisories.block false \
    && composer config --global audit.abandoned ignore

# Laravel 9 + Voyager 1.6 (vulnerable: default creds + media upload RCE)
RUN composer create-project laravel/laravel:^9.0 . --no-interaction --prefer-dist \
    && composer config policy.advisories.block false \
    && composer require tcg/voyager:1.6.* --no-interaction --with-all-dependencies \
    && rm -rf /root/.composer/cache

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && chown -R www-data:www-data /var/www/html

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
