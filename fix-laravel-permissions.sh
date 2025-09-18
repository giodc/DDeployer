#!/bin/bash

# DDeployer Laravel Permissions Fix Script
# Run this script if you encounter Laravel bootstrap/cache directory errors

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
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

# Configuration
INSTALL_DIR="/opt/ddeployer"

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Fix Laravel permissions
fix_permissions() {
    print_status "Fixing Laravel permissions..."
    
    if [[ ! -d "$INSTALL_DIR" ]]; then
        print_error "DDeployer installation directory not found: $INSTALL_DIR"
        exit 1
    fi
    
    cd "$INSTALL_DIR"
    
    # Check if Docker Compose is running
    if ! docker-compose ps | grep -q "Up"; then
        print_status "Starting DDeployer services..."
        docker-compose up -d
        sleep 30
    fi
    
    # Create Laravel directories if they don't exist
    print_status "Creating Laravel directories..."
    docker-compose exec -T admin mkdir -p bootstrap/cache
    docker-compose exec -T admin mkdir -p storage/logs
    docker-compose exec -T admin mkdir -p storage/framework/cache
    docker-compose exec -T admin mkdir -p storage/framework/sessions
    docker-compose exec -T admin mkdir -p storage/framework/views
    
    # Set proper permissions
    print_status "Setting proper permissions..."
    docker-compose exec -T admin chmod -R 775 bootstrap/cache storage
    docker-compose exec -T admin chown -R www-data:www-data bootstrap/cache storage
    
    # Check if Laravel .env file exists
    print_status "Checking Laravel .env file..."
    if ! docker-compose exec -T admin test -f .env; then
        print_status "Creating Laravel .env file from .env.example..."
        docker-compose exec -T admin cp .env.example .env
        
        # Generate a new APP_KEY if missing
        if ! docker-compose exec -T admin grep -q "APP_KEY=base64:" .env; then
            print_status "Generating Laravel application key..."
            docker-compose exec -T admin php artisan key:generate --force
        fi
    else
        print_success "Laravel .env file exists"
    fi
    
    # Install Laravel UI package if missing
    print_status "Checking Laravel UI package..."
    if ! docker-compose exec -T admin composer show laravel/ui > /dev/null 2>&1; then
        print_status "Installing Laravel UI package..."
        docker-compose exec -T admin composer require laravel/ui --no-interaction
    else
        print_success "Laravel UI package is already installed"
    fi
    
    # Test Redis connectivity and configure accordingly
    print_status "Testing Redis connectivity..."
    if docker-compose exec -T admin php -r "try { \$redis = new Redis(); \$redis->connect('redis', 6379); echo 'Redis OK'; } catch (Exception \$e) { echo 'Redis Failed: ' . \$e->getMessage(); }" 2>/dev/null | grep -q "Redis OK"; then
        print_status "Redis is available, enabling Redis drivers..."
        docker-compose exec -T admin sed -i 's/CACHE_DRIVER=file/CACHE_DRIVER=redis/' .env || true
        docker-compose exec -T admin sed -i 's/SESSION_DRIVER=file/SESSION_DRIVER=redis/' .env || true
        docker-compose exec -T admin sed -i 's/QUEUE_CONNECTION=sync/QUEUE_CONNECTION=redis/' .env || true
    else
        print_warning "Redis not available, ensuring file-based drivers are configured..."
        docker-compose exec -T admin sed -i 's/CACHE_DRIVER=redis/CACHE_DRIVER=file/' .env || true
        docker-compose exec -T admin sed -i 's/SESSION_DRIVER=redis/SESSION_DRIVER=file/' .env || true
        docker-compose exec -T admin sed -i 's/QUEUE_CONNECTION=redis/QUEUE_CONNECTION=sync/' .env || true
    fi
    
    # Clear Laravel caches
    print_status "Clearing Laravel caches..."
    docker-compose exec -T admin php artisan config:clear || true
    docker-compose exec -T admin php artisan cache:clear || true
    docker-compose exec -T admin php artisan route:clear || true
    docker-compose exec -T admin php artisan view:clear || true
    
    # Test composer install
    print_status "Testing composer install..."
    if docker-compose exec -T admin composer install --no-dev --optimize-autoloader --no-interaction; then
        print_success "Composer install successful!"
    else
        print_warning "Composer install failed, trying with --ignore-platform-reqs..."
        if docker-compose exec -T admin composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs; then
            print_success "Composer install successful with --ignore-platform-reqs!"
        else
            print_error "Composer install failed. Please check the logs."
            exit 1
        fi
    fi
    
    print_success "Laravel permissions fixed successfully!"
}

# Show usage
show_help() {
    cat << EOF
DDeployer Laravel Permissions Fix Script

This script fixes common Laravel permission issues that can occur during installation.

Usage: $0

The script will:
1. Create required Laravel directories
2. Set proper permissions (775) for bootstrap/cache and storage
3. Install Laravel UI package if missing
4. Clear Laravel caches
5. Test composer install

Run this script if you encounter errors like:
- "The /var/www/html/bootstrap/cache directory must be present and writable"
- "Auth::routes() method requires laravel/ui package"
EOF
}

# Main function
main() {
    echo "========================================"
    echo "  DDeployer Laravel Permissions Fix"
    echo "========================================"
    echo
    
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    check_root
    fix_permissions
    
    echo
    print_success "🎉 Laravel permissions have been fixed!"
    print_status "You can now run composer install without errors."
    echo
}

# Run main function
main "$@"
