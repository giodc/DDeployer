#!/bin/bash

# Fix DDeployer Admin Container Issues
# Run this on your remote server to fix the FrankenPHP/supervisor issues

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
echo "  DDeployer Admin Container Fix"
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

# Stop the admin container
print_status "Stopping admin container..."
$COMPOSE_CMD stop admin || true

# Fix the supervisor configuration
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

print_success "Supervisor configuration updated"

# Create the missing view.php configuration if it doesn't exist
print_status "Ensuring view.php configuration exists..."
if [[ ! -f "admin/config/view.php" ]]; then
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
    print_success "Created missing view.php configuration"
else
    print_success "view.php configuration already exists"
fi

# Rebuild and restart the admin container
print_status "Rebuilding admin container..."
$COMPOSE_CMD build --no-cache admin

print_status "Starting admin container..."
$COMPOSE_CMD up -d admin

# Wait for container to start
print_status "Waiting for admin container to start..."
sleep 10

# Check if container is running
if docker ps --format "{{.Names}}" | grep -q "ddeployer-admin"; then
    print_success "Admin container is now running!"
    
    # Run the Laravel fixes inside the container
    print_status "Running Laravel configuration fixes..."
    
    # Create Laravel directories
    docker exec ddeployer-admin mkdir -p bootstrap/cache storage/logs storage/framework/cache storage/framework/sessions storage/framework/views
    
    # Set permissions
    docker exec ddeployer-admin chmod -R 775 bootstrap/cache storage
    docker exec ddeployer-admin chown -R www-data:www-data bootstrap/cache storage
    
    # Install composer dependencies
    print_status "Installing composer dependencies..."
    if docker exec ddeployer-admin composer install --no-dev --optimize-autoloader --no-interaction; then
        print_success "Composer install successful"
    else
        print_warning "Composer install failed, trying with --ignore-platform-reqs..."
        docker exec ddeployer-admin composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs
    fi
    
    # Clear Laravel caches
    print_status "Clearing Laravel caches..."
    docker exec ddeployer-admin php artisan config:clear || true
    docker exec ddeployer-admin php artisan cache:clear || true
    docker exec ddeployer-admin php artisan route:clear || true
    docker exec ddeployer-admin php artisan view:clear || true
    
    print_success "Laravel configuration completed"
    
    # Show final status
    echo
    print_status "Final container status:"
    $COMPOSE_CMD ps
    
    echo
    print_success "🎉 Admin container fix completed!"
    print_status "You should now be able to access the admin panel at port 8080"
    
else
    print_error "Admin container failed to start. Checking logs..."
    docker logs --tail 20 ddeployer-admin || print_error "Could not get container logs"
fi

echo
