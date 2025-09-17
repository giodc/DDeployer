#!/bin/bash

# DDeployer Setup Verification Script
# This script verifies that all components are properly configured

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
echo "    DDeployer Setup Verification"
echo "========================================"
echo

# Check if we're in the right directory
print_status "Checking current directory..."
if [[ ! -f "docker-compose.yml" ]]; then
    print_error "docker-compose.yml not found. Please run this script from the DDeployer directory."
    exit 1
fi
print_success "Found docker-compose.yml"

# Check required directories
print_status "Checking directory structure..."
required_dirs=("admin" "templates" "config" "data")
for dir in "${required_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        print_success "Directory exists: $dir"
    else
        print_error "Missing directory: $dir"
        exit 1
    fi
done

# Check required files
print_status "Checking required files..."
required_files=(
    "install.sh"
    "admin/composer.json"
    "admin/artisan"
    "admin/bootstrap/app.php"
    "admin/public/index.php"
    "templates/wordpress/docker-compose.yml"
    "templates/laravel/docker-compose.yml"
    "templates/php/docker-compose.yml"
    "config/mysql/my.cnf"
)

missing_files=0
for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        print_success "File exists: $file"
    else
        print_error "Missing file: $file"
        missing_files=$((missing_files + 1))
    fi
done

if [[ $missing_files -gt 0 ]]; then
    print_error "$missing_files files are missing. Installation may fail."
    exit 1
fi

# Check Laravel admin structure
print_status "Checking Laravel admin structure..."
laravel_dirs=(
    "admin/app/Http/Controllers"
    "admin/app/Models"
    "admin/app/Services"
    "admin/database/migrations"
    "admin/resources/views"
    "admin/storage/logs"
    "admin/storage/framework"
    "admin/config"
)

for dir in "${laravel_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        print_success "Laravel directory exists: $dir"
    else
        print_warning "Laravel directory missing: $dir"
    fi
done

# Check Docker requirements
print_status "Checking Docker installation..."
if command -v docker &> /dev/null; then
    docker_version=$(docker --version)
    print_success "Docker installed: $docker_version"
else
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

if command -v docker-compose &> /dev/null; then
    compose_version=$(docker-compose --version)
    print_success "Docker Compose installed: $compose_version"
else
    print_error "Docker Compose is not installed or not in PATH"
    exit 1
fi

# Check Docker daemon
print_status "Checking Docker daemon..."
if docker ps &> /dev/null; then
    print_success "Docker daemon is running"
else
    print_error "Docker daemon is not running. Please start Docker."
    exit 1
fi

# Check permissions
print_status "Checking file permissions..."
if [[ -x "install.sh" ]]; then
    print_success "install.sh is executable"
else
    print_warning "install.sh is not executable. Run: chmod +x install.sh"
fi

if [[ -x "admin/artisan" ]]; then
    print_success "artisan is executable"
else
    print_warning "artisan is not executable. Run: chmod +x admin/artisan"
fi

# Check available ports
print_status "Checking port availability..."
ports=(80 443 8080 8081 3306 6379)
for port in "${ports[@]}"; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        print_warning "Port $port is in use - this may cause conflicts"
    else
        print_success "Port $port is available"
    fi
done

# Check system resources
print_status "Checking system resources..."

# Memory check
if command -v free &> /dev/null; then
    total_mem=$(free -m | awk 'NR==2{print $2}')
    if [[ $total_mem -ge 2048 ]]; then
        print_success "Memory: ${total_mem}MB (sufficient)"
    else
        print_warning "Memory: ${total_mem}MB (minimum 2GB recommended)"
    fi
fi

# Disk space check
available_space=$(df . | awk 'NR==2 {print $4}')
if [[ $available_space -ge 10485760 ]]; then  # 10GB in KB
    print_success "Disk space: sufficient"
else
    print_warning "Disk space: less than 10GB available"
fi

echo
print_status "Verification Summary:"

# Final recommendations
echo
print_status "Installation Recommendations:"
echo "1. Run: sudo ./install.sh --local (for development)"
echo "2. Or run: sudo ./install.sh --production (for production)"
echo "3. Access admin panel at: http://localhost:8080"
echo "4. Default login: admin@ddeployer.local / admin123"

echo
print_success "✅ Setup verification completed!"
print_status "You can now proceed with the installation."
