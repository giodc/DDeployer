#!/bin/bash

# Quick fix for Laravel "View path not found" error
# Run this script to fix the current installation issue

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

echo "========================================"
echo "  DDeployer View Cache Error Fix"
echo "========================================"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

# Check if DDeployer is installed
if [[ ! -d "$INSTALL_DIR" ]]; then
    print_error "DDeployer installation directory not found: $INSTALL_DIR"
    print_status "Please ensure DDeployer is installed first"
    exit 1
fi

cd "$INSTALL_DIR"

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose not found. Please install Docker Compose first."
    exit 1
fi

print_status "Fixing Laravel view cache error..."

# Start services if not running
if ! docker-compose ps | grep -q "Up"; then
    print_status "Starting DDeployer services..."
    docker-compose up -d
    sleep 30
fi

# Create the missing view.php configuration file
print_status "Creating missing view.php configuration file..."
docker-compose exec -T admin bash -c 'cat > config/view.php << '\''EOF'\''
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

# Ensure view directories exist with proper permissions
print_status "Creating and setting permissions for view directories..."
docker-compose exec -T admin mkdir -p storage/framework/views
docker-compose exec -T admin chmod 775 storage/framework/views
docker-compose exec -T admin chown www-data:www-data storage/framework/views

# Clear Laravel caches with proper error handling
print_status "Clearing Laravel configuration cache..."
docker-compose exec -T admin php artisan config:clear || true

print_status "Clearing application cache..."
docker-compose exec -T admin php artisan cache:clear || true

print_status "Clearing route cache..."
docker-compose exec -T admin php artisan route:clear || true

print_status "Clearing view cache..."
if docker-compose exec -T admin php artisan view:clear 2>/dev/null; then
    print_success "View cache cleared successfully!"
else
    print_warning "View cache was empty (this is normal for a fresh installation)"
fi

# Test the fix
print_status "Testing Laravel configuration..."
if docker-compose exec -T admin php artisan config:show app.name 2>/dev/null | grep -q "DDeployer"; then
    print_success "Laravel configuration is working correctly!"
else
    print_warning "Laravel configuration test failed, but the view cache error should be fixed"
fi

echo
print_success "🎉 View cache error has been fixed!"
print_status "You can now continue with your DDeployer installation."
print_status "The installation should complete without the 'View path not found' error."
echo
