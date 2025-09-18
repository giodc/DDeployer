#!/bin/bash

# DDeployer Installation Validation Script
# Validates that the installation is working correctly

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
    echo -e "${GREEN}[✅ PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️  WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌ FAIL]${NC} $1"
}

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNING=0

test_result() {
    if [[ $1 -eq 0 ]]; then
        print_success "$2"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_error "$2"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

test_warning() {
    print_warning "$1"
    TESTS_WARNING=$((TESTS_WARNING + 1))
}

echo "========================================"
echo "  DDeployer Installation Validation"
echo "========================================"
echo

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
echo

# Test 1: Check if all containers are running
print_status "Testing container status..."
EXPECTED_CONTAINERS=("ddeployer-traefik" "ddeployer-mariadb" "ddeployer-redis" "ddeployer-admin")
for container in "${EXPECTED_CONTAINERS[@]}"; do
    if docker ps --format "{{.Names}}" | grep -q "$container"; then
        if docker ps --format "{{.Names}}\t{{.Status}}" | grep "$container" | grep -q "Up"; then
            print_success "Container $container is running"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            print_error "Container $container exists but is not running"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        print_error "Container $container not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
done

echo

# Test 2: Check database connectivity
print_status "Testing database connectivity..."
if docker exec ddeployer-mariadb mysql -uddeployer -p$(grep DB_PASSWORD .env | cut -d'=' -f2) -e "SELECT 1;" > /dev/null 2>&1; then
    print_success "Database connection successful"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_error "Database connection failed"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 3: Check Redis connectivity
print_status "Testing Redis connectivity..."
if docker exec ddeployer-admin php -r "try { \$redis = new Redis(); \$redis->connect('redis', 6379); echo 'OK'; } catch (Exception \$e) { echo 'FAIL'; }" 2>/dev/null | grep -q "OK"; then
    print_success "Redis connection successful"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    test_warning "Redis connection failed - using file-based drivers"
fi

echo

# Test 4: Check Laravel application
print_status "Testing Laravel application..."
if docker exec ddeployer-admin php artisan --version > /dev/null 2>&1; then
    print_success "Laravel artisan is working"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_error "Laravel artisan failed"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 5: Check Laravel configuration
print_status "Testing Laravel configuration..."
if docker exec ddeployer-admin php artisan config:show app.key 2>/dev/null | grep -q "base64:"; then
    print_success "Laravel application key is configured"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_error "Laravel application key missing"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 6: Check Laravel directories and permissions
print_status "Testing Laravel directories..."
LARAVEL_DIRS=("bootstrap/cache" "storage/logs" "storage/framework/cache" "storage/framework/sessions" "storage/framework/views")
for dir in "${LARAVEL_DIRS[@]}"; do
    if docker exec ddeployer-admin test -d "$dir" && docker exec ddeployer-admin test -w "$dir"; then
        print_success "Directory $dir exists and is writable"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_error "Directory $dir missing or not writable"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
done

echo

# Test 7: Check web server response
print_status "Testing web server response..."
ADMIN_PORT=$(grep ADMIN_PORT .env | cut -d'=' -f2)
if curl -f -s http://localhost:$ADMIN_PORT/test.php > /dev/null 2>&1; then
    print_success "Web server responding on port $ADMIN_PORT"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_error "Web server not responding on port $ADMIN_PORT"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 8: Check Traefik dashboard
print_status "Testing Traefik dashboard..."
if curl -f -s http://localhost:8081/api/rawdata > /dev/null 2>&1; then
    print_success "Traefik dashboard accessible on port 8081"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    test_warning "Traefik dashboard not accessible on port 8081"
fi

echo

# Test 9: Check configuration files
print_status "Testing configuration files..."
CONFIG_FILES=("config/app.php" "config/database.php" "config/view.php" ".env")
for file in "${CONFIG_FILES[@]}"; do
    if docker exec ddeployer-admin test -f "$file"; then
        print_success "Configuration file $file exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_error "Configuration file $file missing"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
done

# Test 10: Check systemd service
print_status "Testing systemd service..."
if systemctl is-enabled ddeployer > /dev/null 2>&1; then
    print_success "DDeployer systemd service is enabled"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    test_warning "DDeployer systemd service not enabled"
fi

if systemctl is-active ddeployer > /dev/null 2>&1; then
    print_success "DDeployer systemd service is active"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    test_warning "DDeployer systemd service not active"
fi

echo

# Test 11: Check Laravel migrations
print_status "Testing database migrations..."
if docker exec ddeployer-admin php artisan migrate:status > /dev/null 2>&1; then
    print_success "Database migrations are working"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    test_warning "Database migrations not run or failed"
fi

# Test 12: Check composer dependencies
print_status "Testing composer dependencies..."
if docker exec ddeployer-admin composer show laravel/ui > /dev/null 2>&1; then
    print_success "Laravel UI package is installed"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_error "Laravel UI package missing"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo
echo "========================================"
echo "  Validation Results"
echo "========================================"
echo
print_success "Tests Passed: $TESTS_PASSED"
if [[ $TESTS_WARNING -gt 0 ]]; then
    print_warning "Warnings: $TESTS_WARNING"
fi
if [[ $TESTS_FAILED -gt 0 ]]; then
    print_error "Tests Failed: $TESTS_FAILED"
fi

echo

if [[ $TESTS_FAILED -eq 0 ]]; then
    print_success "🎉 All critical tests passed! DDeployer is working correctly."
    echo
    print_status "🌐 Access your admin panel at: http://your-server-ip:$ADMIN_PORT"
    print_status "📊 Traefik dashboard at: http://your-server-ip:8081"
    echo
    exit 0
else
    print_error "❌ Some tests failed. Please check the issues above."
    echo
    print_status "🔧 To fix common issues, run:"
    print_status "  sudo ./fix-laravel-500.sh"
    print_status "  sudo ./complete-admin-fix.sh"
    echo
    exit 1
fi
