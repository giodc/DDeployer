FROM dunglas/frankenphp:php8.3

# Install WordPress dependencies
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install pdo_mysql mysqli zip

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Install WordPress CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.8.1/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Download WordPress
WORKDIR /var/www/html
RUN wp core download --allow-root

# Copy WordPress configuration
COPY wp-config.php /var/www/html/
COPY .htaccess /var/www/html/

# Install WordPress plugins for performance
RUN wp plugin install redis-cache --allow-root --activate
RUN wp plugin install w3-total-cache --allow-root --activate

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

EXPOSE 80

CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]
