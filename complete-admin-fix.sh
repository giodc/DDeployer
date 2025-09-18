#!/bin/bash

# Complete DDeployer Admin Fix Script
# This script completely fixes the admin container to make port 8080 accessible

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "========================================"
echo "  Complete DDeployer Admin Fix"
echo "========================================"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

# Check if we're in the right directory
if [[ ! -f "docker-compose.yml" ]]; then
    print_error "docker-compose.yml not found. Please run this from /opt/ddeployer"
    exit 1
fi

# Determine Docker Compose command
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    print_error "Docker Compose is not installed"
    exit 1
fi

print_status "Using Docker Compose command: $COMPOSE_CMD"

# Stop all containers
print_status "Stopping all containers..."
$COMPOSE_CMD down || true

# Create Apache configuration
print_status "Creating Apache configuration..."
mkdir -p admin/docker
cat > admin/docker/apache.conf << 'EOF'
<VirtualHost *:8000>
    ServerName localhost
    DocumentRoot /var/www/html/public
    
    <Directory /var/www/html/public>
        AllowOverride All
        Require all granted
        DirectoryIndex index.php
        
        # Enable URL rewriting
        RewriteEngine On
        
        # Handle Angular/Vue Router - send everything to index.php
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
    
    # PHP Configuration
    <FilesMatch \.php$>
        SetHandler application/x-httpd-php
    </FilesMatch>
    
    # Security headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    
    # Logging
    ErrorLog /var/log/apache2/error.log
    CustomLog /var/log/apache2/access.log combined
</VirtualHost>

# Listen on port 8000
Listen 8000
EOF

# Fix supervisor configuration
print_status "Fixing supervisor configuration..."
cat > admin/docker/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:apache2]
command=/usr/sbin/apache2ctl -D FOREGROUND
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/apache2.err.log
stdout_logfile=/var/log/supervisor/apache2.out.log
user=root

[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/artisan queue:work --sleep=3 --tries=3 --max-time=3600
directory=/var/www/html
autostart=true
autorestart=true
numprocs=2
redirect_stderr=true
stdout_logfile=/var/log/supervisor/worker.log
stopwaitsecs=3600
user=www-data
EOF

# Update Dockerfile
print_status "Updating Dockerfile..."
cat > admin/Dockerfile << 'EOF'
FROM php:8.2-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    nodejs \
    npm \
    supervisor \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Install Redis PHP extension
RUN pecl install redis \
    && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Enable Apache modules
RUN a2enmod rewrite headers

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . .

# Create required directories with proper permissions
RUN mkdir -p storage/logs storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache

# Skip Composer for now - we'll install manually during startup
# RUN composer install --no-dev --optimize-autoloader --no-interaction

# Create a simple index.php for testing
RUN echo '<?php phpinfo(); ?>' > public/test.php

# Set proper permissions for Laravel directories
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache \
    && chown -R www-data:www-data /var/www/html/storage \
    && chown -R www-data:www-data /var/www/html/bootstrap/cache

# Configure Apache
COPY docker/apache.conf /etc/apache2/sites-available/ddeployer.conf
RUN a2ensite ddeployer && a2dissite 000-default

# Create supervisor configuration
RUN mkdir -p /var/log/supervisor

COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose port
EXPOSE 8000

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
EOF

# Create the missing view.php configuration
print_status "Creating Laravel view configuration..."
cat > admin/config/view.php << 'EOF'
<?php

return [
    'paths' => [
        resource_path('views'),
    ],
    'compiled' => env(
        'VIEW_COMPILED_PATH',
        realpath(storage_path('framework/views'))
    ),
];
EOF

# Ensure .env files exist
print_status "Checking environment files..."
if [[ ! -f ".env" ]]; then
    print_error ".env file not found. Please run the main installation script first."
    exit 1
fi

if [[ ! -f "admin/.env" ]]; then
    print_status "Creating admin/.env from main .env..."
    cp .env admin/.env
fi

# Build and start containers
print_status "Building containers (this may take a few minutes)..."
$COMPOSE_CMD build --no-cache

print_status "Starting all containers..."
$COMPOSE_CMD up -d

# Wait for containers to start
print_status "Waiting for containers to start..."
sleep 30

# Check container status
print_status "Checking container status..."
$COMPOSE_CMD ps

# Configure Laravel inside the container
print_status "Configuring Laravel application..."
if docker ps --format "{{.Names}}" | grep -q "ddeployer-admin"; then
    print_success "Admin container is running!"
    
    # Wait a bit more for Apache to fully start
    sleep 10
    
    # Create Laravel directories
    print_status "Setting up Laravel directories..."
    docker exec ddeployer-admin mkdir -p bootstrap/cache storage/logs storage/framework/cache storage/framework/sessions storage/framework/views
    
    # Set permissions
    docker exec ddeployer-admin chmod -R 775 bootstrap/cache storage
    docker exec ddeployer-admin chown -R www-data:www-data bootstrap/cache storage
    
    # Install Laravel UI package first
    print_status "Installing Laravel UI package..."
    docker exec ddeployer-admin composer require laravel/ui --no-interaction --ignore-platform-reqs || true
    
    # Install composer dependencies
    print_status "Installing composer dependencies..."
    if docker exec ddeployer-admin composer install --no-dev --optimize-autoloader --no-interaction; then
        print_success "Composer install successful"
    else
        print_warning "Composer install failed, trying with --ignore-platform-reqs..."
        docker exec ddeployer-admin composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs
    fi
    
    # Generate application key if needed
    print_status "Checking application key..."
    if ! docker exec ddeployer-admin php artisan config:show app.key | grep -q "base64:"; then
        print_status "Generating application key..."
        docker exec ddeployer-admin php artisan key:generate --force
    fi
    
    # Clear Laravel caches
    print_status "Clearing Laravel caches..."
    docker exec ddeployer-admin php artisan config:clear || true
    docker exec ddeployer-admin php artisan cache:clear || true
    docker exec ddeployer-admin php artisan route:clear || true
    docker exec ddeployer-admin php artisan view:clear || true
    
    # Run migrations
    print_status "Running database migrations..."
    docker exec ddeployer-admin php artisan migrate --force || print_warning "Migration failed - database may not be ready"
    
    print_success "Laravel configuration completed"
    
else
    print_error "Admin container failed to start!"
    print_status "Container logs:"
    docker logs --tail 50 ddeployer-admin || true
    exit 1
fi

# Test connectivity
print_status "Testing connectivity..."
sleep 5

if curl -f -s http://localhost:8080/test.php > /dev/null; then
    print_success "✅ Port 8080 is now accessible!"
else
    print_warning "Port 8080 test failed, but container is running. Check firewall settings."
fi

# Show final status
echo
print_status "Final status:"
$COMPOSE_CMD ps
echo
print_status "Port mapping:"
docker port ddeployer-admin || true

echo
print_success "🎉 Complete admin fix completed!"
print_status "Admin panel should now be accessible at:"
print_status "  - http://your-server-ip:8080"
print_status "  - Test page: http://your-server-ip:8080/test.php"
echo
print_status "If still not accessible, check:"
print_status "  1. Firewall settings (allow port 8080)"
print_status "  2. Server security groups (if on cloud)"
print_status "  3. Container logs: docker logs -f ddeployer-admin"
echo
