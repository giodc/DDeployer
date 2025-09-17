FROM dunglas/frankenphp:php{{PHP_VERSION}}

# Install common PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    && docker-php-ext-install pdo_mysql mysqli mbstring exif pcntl bcmath gd zip

# Install Redis extension if needed
{{REDIS_EXTENSION}}

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . .

# Install Composer dependencies if composer.json exists
RUN if [ -f "composer.json" ]; then composer install --no-dev --optimize-autoloader --no-interaction; fi

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \;

# Create Caddyfile for FrankenPHP
RUN echo ':80 {\n    root * /var/www/html\n    php_fastcgi unix//var/run/php/php-fpm.sock\n    file_server\n    try_files {path} {path}/ /index.php?{query}\n}' > /etc/caddy/Caddyfile

EXPOSE 80

CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]
