#!/bin/bash

# Quick DDeployer Update Script
# For routine updates without full rebuild

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
echo "  DDeployer Quick Update"
echo "========================================"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

# Check if we're in the right directory
if [[ ! -f "docker-compose.yml" ]]; then
    print_error "Please run this from /opt/ddeployer"
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

# Check if it's a git repository
if [[ ! -d ".git" ]]; then
    print_error "Not a Git repository. Use the full update script instead."
    exit 1
fi

# Quick backup of env files
print_status "Backing up configuration..."
cp .env .env.backup || true
cp admin/.env admin/.env.backup 2>/dev/null || true

# Pull latest changes
print_status "Pulling latest changes..."
git pull origin main

# Restore env files
print_status "Restoring configuration..."
cp .env.backup .env || true
cp admin/.env.backup admin/.env 2>/dev/null || true
rm -f .env.backup admin/.env.backup

# Restart containers
print_status "Restarting containers..."
$COMPOSE_CMD restart

# Clear Laravel caches
print_status "Clearing caches..."
sleep 10
docker exec ddeployer-admin php artisan config:clear || true
docker exec ddeployer-admin php artisan cache:clear || true
docker exec ddeployer-admin php artisan view:clear || true

print_success "✅ Quick update completed!"
print_status "For major updates, use: sudo ./update-ddeployer.sh"
echo
