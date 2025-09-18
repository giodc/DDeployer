#!/bin/bash

# DDeployer Container Diagnostic Script
# Run this on your remote server to diagnose container issues

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
echo "  DDeployer Container Diagnostics"
echo "========================================"
echo

# Check if we're in the right directory
if [[ ! -f "docker-compose.yml" ]]; then
    print_error "docker-compose.yml not found. Please run this from /opt/ddeployer"
    exit 1
fi

# Check Docker installation
print_status "Checking Docker installation..."
if command -v docker &> /dev/null; then
    docker --version
    print_success "Docker is installed"
else
    print_error "Docker is not installed"
    exit 1
fi

# Check Docker Compose installation
print_status "Checking Docker Compose installation..."
if command -v docker-compose &> /dev/null; then
    docker-compose --version
    COMPOSE_CMD="docker-compose"
    print_success "Docker Compose is installed"
elif docker compose version &> /dev/null; then
    docker compose version
    COMPOSE_CMD="docker compose"
    print_success "Docker Compose (plugin) is installed"
else
    print_error "Docker Compose is not installed"
    exit 1
fi

# Check container status
print_status "Checking container status..."
echo "Container Status:"
$COMPOSE_CMD ps

echo
print_status "Checking running containers..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check for admin container specifically
echo
print_status "Checking admin container logs (last 50 lines)..."
if docker ps --format "{{.Names}}" | grep -q "ddeployer-admin"; then
    print_success "Admin container is running"
    echo "Recent admin container logs:"
    docker logs --tail 50 ddeployer-admin
else
    print_error "Admin container is not running"
    echo "Checking if admin container exists but is stopped:"
    if docker ps -a --format "{{.Names}}" | grep -q "ddeployer-admin"; then
        print_warning "Admin container exists but is stopped"
        echo "Admin container logs:"
        docker logs --tail 50 ddeployer-admin
    else
        print_error "Admin container does not exist"
    fi
fi

# Check network connectivity
echo
print_status "Checking port connectivity..."
if command -v netstat &> /dev/null; then
    echo "Listening ports:"
    netstat -tuln | grep -E ":(8080|8081|80|443)"
elif command -v ss &> /dev/null; then
    echo "Listening ports:"
    ss -tuln | grep -E ":(8080|8081|80|443)"
else
    print_warning "Cannot check port status (netstat/ss not available)"
fi

# Check Docker networks
echo
print_status "Checking Docker networks..."
docker network ls | grep ddeployer || print_warning "DDeployer network not found"

# Check volumes
echo
print_status "Checking Docker volumes..."
docker volume ls | grep ddeployer || print_warning "No DDeployer volumes found"

# Check .env file
echo
print_status "Checking environment configuration..."
if [[ -f ".env" ]]; then
    print_success ".env file exists"
    echo "Environment variables:"
    grep -E "^(ADMIN_PORT|APP_ENV|DB_|REDIS_)" .env || print_warning "Some environment variables may be missing"
else
    print_error ".env file not found"
fi

# Check admin .env file
if [[ -f "admin/.env" ]]; then
    print_success "admin/.env file exists"
else
    print_error "admin/.env file not found"
fi

echo
print_status "Diagnostic complete. If admin container is not running, try:"
echo "  1. $COMPOSE_CMD up -d admin"
echo "  2. $COMPOSE_CMD restart admin"
echo "  3. Check logs with: docker logs -f ddeployer-admin"
echo
