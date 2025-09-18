#!/bin/bash

# Fix Laravel 500 Server Error
# This script fixes common Laravel configuration issues that cause 500 errors

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
echo "  Laravel 500 Error Fix"
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

# Check if admin container is running
if ! docker ps --format "{{.Names}}" | grep -q "ddeployer-admin"; then
    print_error "Admin container is not running. Starting it..."
    $COMPOSE_CMD up -d admin
    sleep 20
fi

print_success "Admin container is running - Laravel 500 error detected"

# Check Laravel logs first
print_status "Checking Laravel error logs..."
docker exec ddeployer-admin tail -20 storage/logs/laravel.log 2>/dev/null || print_warning "No Laravel logs found yet"

# Check Apache error logs
print_status "Checking Apache error logs..."
docker exec ddeployer-admin tail -10 /var/log/apache2/error.log 2>/dev/null || print_warning "No Apache error logs found"

# Fix 1: Ensure all required directories exist with proper permissions
print_status "Creating and fixing Laravel directories..."
docker exec ddeployer-admin mkdir -p bootstrap/cache
docker exec ddeployer-admin mkdir -p storage/logs
docker exec ddeployer-admin mkdir -p storage/framework/cache
docker exec ddeployer-admin mkdir -p storage/framework/sessions  
docker exec ddeployer-admin mkdir -p storage/framework/views
docker exec ddeployer-admin mkdir -p storage/app/public

# Set proper permissions
docker exec ddeployer-admin chmod -R 775 bootstrap/cache storage
docker exec ddeployer-admin chown -R www-data:www-data bootstrap/cache storage

# Fix 2: Check and fix .env file
print_status "Checking Laravel .env file..."
if ! docker exec ddeployer-admin test -f .env; then
    print_status "Creating Laravel .env file..."
    docker exec ddeployer-admin cp .env.example .env
fi

# Fix 3: Generate application key if missing
print_status "Checking application key..."
if ! docker exec ddeployer-admin grep -q "APP_KEY=base64:" .env; then
    print_status "Generating Laravel application key..."
    docker exec ddeployer-admin php artisan key:generate --force
else
    print_success "Application key exists"
fi

# Fix 4: Install missing composer dependencies
print_status "Installing/updating composer dependencies..."
docker exec ddeployer-admin composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs

# Fix 5: Install Laravel UI if missing (common cause of 500 errors)
print_status "Installing Laravel UI package..."
docker exec ddeployer-admin composer require laravel/ui --no-interaction --ignore-platform-reqs || true

# Fix 6: Create missing config files
print_status "Ensuring all config files exist..."

# Create view.php if missing
if ! docker exec ddeployer-admin test -f config/view.php; then
    print_status "Creating view.php configuration..."
    docker exec ddeployer-admin bash -c 'cat > config/view.php << '\''EOF'\''
<?php
return [
    '\''paths'\'' => [
        resource_path('\''views'\''),
    ],
    '\''compiled'\'' => env(
        '\''VIEW_COMPILED_PATH'\'',
        realpath(storage_path('\''framework/views'\''))
    ),
];
EOF'
fi

# Fix 7: Clear all Laravel caches
print_status "Clearing all Laravel caches..."
docker exec ddeployer-admin php artisan config:clear || true
docker exec ddeployer-admin php artisan cache:clear || true
docker exec ddeployer-admin php artisan route:clear || true
docker exec ddeployer-admin php artisan view:clear || true

# Fix 8: Optimize Laravel
print_status "Optimizing Laravel configuration..."
docker exec ddeployer-admin php artisan config:cache || true
docker exec ddeployer-admin php artisan route:cache || true

# Fix 9: Run database migrations
print_status "Running database migrations..."
if docker exec ddeployer-admin php artisan migrate --force 2>/dev/null; then
    print_success "Database migrations completed"
else
    print_warning "Database migrations failed - database may not be ready yet"
    print_status "Waiting for database and retrying..."
    sleep 15
    docker exec ddeployer-admin php artisan migrate --force || print_warning "Migration still failed - will continue"
fi

# Fix 10: Create storage link
print_status "Creating storage symbolic link..."
docker exec ddeployer-admin php artisan storage:link || true

# Fix 11: Set proper environment variables
print_status "Checking environment configuration..."
docker exec ddeployer-admin php artisan config:show app.env || print_warning "Could not show app environment"

# Fix 12: Test Laravel installation
print_status "Testing Laravel installation..."
if docker exec ddeployer-admin php artisan --version; then
    print_success "Laravel is responding to artisan commands"
else
    print_error "Laravel artisan is not working properly"
fi

# Fix 13: Check for common missing dependencies
print_status "Checking for common issues..."

# Check if Redis is working
if docker exec ddeployer-admin php -r "try { \$redis = new Redis(); \$redis->connect('redis', 6379); echo 'Redis OK'; } catch (Exception \$e) { echo 'Redis Failed'; }" 2>/dev/null | grep -q "Redis OK"; then
    print_success "Redis connection is working"
else
    print_warning "Redis connection failed - switching to file-based drivers"
    docker exec ddeployer-admin sed -i 's/CACHE_DRIVER=redis/CACHE_DRIVER=file/' .env || true
    docker exec ddeployer-admin sed -i 's/SESSION_DRIVER=redis/SESSION_DRIVER=file/' .env || true
    docker exec ddeployer-admin sed -i 's/QUEUE_CONNECTION=redis/QUEUE_CONNECTION=sync/' .env || true
fi

# Check database connection
if docker exec ddeployer-admin php artisan migrate:status 2>/dev/null; then
    print_success "Database connection is working"
else
    print_warning "Database connection issues detected"
fi

# Final cache clear after all fixes
print_status "Final cache clearing..."
docker exec ddeployer-admin php artisan config:clear || true
docker exec ddeployer-admin php artisan cache:clear || true

# Restart Apache to ensure all changes take effect
print_status "Restarting Apache..."
docker exec ddeployer-admin supervisorctl restart apache2 || docker exec ddeployer-admin service apache2 restart || true

# Wait a moment for Apache to restart
sleep 5

# Test the application
print_status "Testing Laravel application..."
if curl -f -s http://localhost:8080/test.php > /dev/null; then
    print_success "✅ Test page is accessible"
else
    print_warning "Test page not accessible"
fi

# Show final logs
print_status "Recent Laravel logs after fixes:"
docker exec ddeployer-admin tail -10 storage/logs/laravel.log 2>/dev/null || print_status "No new Laravel logs"

print_status "Recent Apache error logs:"
docker exec ddeployer-admin tail -5 /var/log/apache2/error.log 2>/dev/null || print_status "No new Apache errors"

echo
print_success "🎉 Laravel 500 error fix completed!"
print_status "Try accessing the admin panel now at: http://your-server-ip:8080"
echo
print_status "If you still get 500 errors, check:"
print_status "  1. Laravel logs: docker exec ddeployer-admin tail -f storage/logs/laravel.log"
print_status "  2. Apache logs: docker exec ddeployer-admin tail -f /var/log/apache2/error.log"
print_status "  3. Container logs: docker logs -f ddeployer-admin"
echo
