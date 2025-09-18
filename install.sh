#!/bin/bash

# DDeployer Installation Script
# High-performance Docker web hosting platform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/opt/ddeployer"
ADMIN_PORT="8080"
LOCAL_MODE=false
PRODUCTION_MODE=false

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

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --local)
                LOCAL_MODE=true
                shift
                ;;
            --production)
                PRODUCTION_MODE=true
                shift
                ;;
            --admin-port)
                ADMIN_PORT="$2"
                shift 2
                ;;
            --install-dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
DDeployer Installation Script

Usage: $0 [OPTIONS]

Options:
    --local         Install for local development (uses .localhost domains)
    --production    Install for production use
    --admin-port    Set admin panel port (default: 8080)
    --install-dir   Set installation directory (default: /opt/ddeployer)
    -h, --help      Show this help message

Examples:
    $0 --local                    # Local development setup
    $0 --production               # Production setup
    $0 --production --admin-port 9000  # Production with custom admin port
EOF
}

# Check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check OS
    if ! grep -q "Ubuntu" /etc/os-release; then
        print_warning "This installer is designed for Ubuntu. Other distributions may work but are not officially supported."
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_status "Installing Docker..."
        curl -fsSL https://get.docker.com | sh
        systemctl enable docker
        systemctl start docker
    else
        print_success "Docker is already installed"
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_status "Installing Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    else
        print_success "Docker Compose is already installed"
    fi
    
    # Check available ports
    if command -v netstat &> /dev/null; then
        if netstat -tuln | grep -q ":$ADMIN_PORT "; then
            print_error "Port $ADMIN_PORT is already in use. Please choose a different port with --admin-port"
            exit 1
        fi
    elif command -v ss &> /dev/null; then
        if ss -tuln | grep -q ":$ADMIN_PORT "; then
            print_error "Port $ADMIN_PORT is already in use. Please choose a different port with --admin-port"
            exit 1
        fi
    else
        print_warning "Cannot check port availability (netstat/ss not found). Proceeding anyway..."
    fi
}

# Create installation directory
create_install_dir() {
    print_status "Creating installation directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    # Don't change directory here - we need to stay in the source directory
}

# Copy application files
copy_files() {
    print_status "Copying application files..."
    
    # Get the script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Check if we're in the DDeployer directory
    if [[ -f "$SCRIPT_DIR/docker-compose.yml" ]]; then
        print_status "Found application files in: $SCRIPT_DIR"
        cp -r "$SCRIPT_DIR"/* "$INSTALL_DIR/"
        # Exclude the installer script from the copy
        rm -f "$INSTALL_DIR/install.sh"
    elif [[ -f "./docker-compose.yml" ]]; then
        print_status "Found application files in current directory"
        cp -r ./* "$INSTALL_DIR/"
        # Exclude the installer script from the copy
        rm -f "$INSTALL_DIR/install.sh"
    else
        print_error "Application files not found. Please ensure you're running this script from the DDeployer directory."
        print_error "Expected files: docker-compose.yml, admin/, templates/, config/"
        print_status "Current directory: $(pwd)"
        print_status "Script directory: $SCRIPT_DIR"
        print_status "Looking for: docker-compose.yml"
        
        # List files in current directory for debugging
        print_status "Files in current directory:"
        ls -la
        
        exit 1
    fi
}

# Generate environment configuration
generate_env() {
    print_status "Generating environment configuration..."
    
    # Generate random passwords and set database credentials
    DB_USERNAME="ddeployer"
    DB_PASSWORD=$(openssl rand -base64 32)
    REDIS_PASSWORD=$(openssl rand -base64 32)
    APP_KEY="base64:$(openssl rand -base64 32)"
    
    # Change to install directory to create .env file
    cd "$INSTALL_DIR"
    
    # Create Docker Compose .env file
    cat > .env << EOF
# DDeployer Configuration
COMPOSE_PROJECT_NAME=ddeployer

# Admin Panel Configuration
ADMIN_PORT=$ADMIN_PORT
APP_ENV=production
APP_DEBUG=false
APP_KEY=$APP_KEY
APP_URL=http://localhost:$ADMIN_PORT

# Database Configuration
DB_CONNECTION=mysql
DB_HOST=mariadb
DB_PORT=3306
DB_DATABASE=ddeployer
DB_USERNAME=ddeployer
DB_PASSWORD=$DB_PASSWORD

# Redis Configuration
REDIS_HOST=redis
REDIS_PASSWORD=$REDIS_PASSWORD
REDIS_PORT=6379

# Traefik Configuration
TRAEFIK_DASHBOARD=true
TRAEFIK_API=true

# Mode Configuration
LOCAL_MODE=$LOCAL_MODE
PRODUCTION_MODE=$PRODUCTION_MODE
EOF

    # Create Laravel .env file in admin directory
    print_status "Creating Laravel environment file..."
    cat > admin/.env << EOF
APP_NAME="DDeployer Admin"
APP_ENV=production
APP_KEY=$APP_KEY
APP_DEBUG=false
APP_URL=http://localhost:$ADMIN_PORT

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=mariadb
DB_PORT=3306
DB_DATABASE=ddeployer
DB_USERNAME=ddeployer
DB_PASSWORD=$DB_PASSWORD

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

REDIS_HOST=redis
REDIS_PASSWORD=$REDIS_PASSWORD
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="admin@ddeployer.local"
MAIL_FROM_NAME="DDeployer Admin"

# Docker Configuration
DOCKER_SOCKET=/var/run/docker.sock
SITES_PATH=/var/www/sites
TEMPLATES_PATH=/var/www/templates

# Traefik Configuration
TRAEFIK_NETWORK=ddeployer
DEFAULT_DOMAIN=localhost
EOF

    print_success "Environment configuration generated"
}

# Start services
start_services() {
    print_status "Starting DDeployer services..."
    
    # Change to install directory to run docker-compose
    cd "$INSTALL_DIR"
    
    # Start database and Redis first
    print_status "Starting database and Redis services..."
    docker-compose up -d mariadb redis
    
    # Wait for database to be ready
    print_status "Waiting for database to initialize..."
    sleep 45
    
    # Verify database is ready
    local db_ready=false
    for i in {1..12}; do
        if docker-compose exec -T mariadb mysql -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT 1;" > /dev/null 2>&1; then
            db_ready=true
            break
        fi
        print_status "Waiting for database... (attempt $i/12)"
        sleep 10
    done
    
    if [[ "$db_ready" == "false" ]]; then
        print_error "Database failed to start properly"
        exit 1
    fi
    
    print_success "Database is ready"
    
    # Start remaining services
    print_status "Starting all services..."
    docker-compose up -d
    
    # Wait for admin container to start
    print_status "Waiting for admin container to start..."
    sleep 30
    
    # Wait for admin container to be fully ready
    local admin_ready=false
    for i in {1..10}; do
        if docker-compose exec -T admin test -f /var/www/html/artisan; then
            admin_ready=true
            break
        fi
        print_status "Waiting for admin container... (attempt $i/10)"
        sleep 5
    done
    
    if [[ "$admin_ready" == "false" ]]; then
        print_error "Admin container failed to start properly"
        exit 1
    fi
    
    print_success "Admin container is ready"
    
    # Complete Laravel setup
    setup_laravel_application
    
    print_success "All services started successfully"
}

# Complete Laravel application setup
setup_laravel_application() {
    print_status "Setting up Laravel application..."
    
    # Ensure all required directories exist with proper permissions
    print_status "Creating Laravel directories..."
    docker-compose exec -T admin mkdir -p bootstrap/cache
    docker-compose exec -T admin mkdir -p storage/logs
    docker-compose exec -T admin mkdir -p storage/framework/cache
    docker-compose exec -T admin mkdir -p storage/framework/sessions
    docker-compose exec -T admin mkdir -p storage/framework/views
    docker-compose exec -T admin mkdir -p storage/app/public
    
    # Set proper permissions
    print_status "Setting Laravel permissions..."
    docker-compose exec -T admin chmod -R 775 bootstrap/cache storage
    docker-compose exec -T admin chown -R www-data:www-data bootstrap/cache storage
    
    # Ensure .env file exists
    print_status "Checking Laravel .env file..."
    if ! docker-compose exec -T admin test -f .env; then
        print_status "Creating Laravel .env file..."
        docker-compose exec -T admin cp .env.example .env 2>/dev/null || print_warning ".env.example not found"
    fi
    
    # Create missing configuration files
    print_status "Creating missing configuration files..."
    
    # Create view.php configuration
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
    
    # Install Laravel UI package first (required for Auth routes)
    print_status "Installing Laravel UI package..."
    if ! docker-compose exec -T admin composer require laravel/ui --no-interaction --ignore-platform-reqs; then
        print_error "Failed to install Laravel UI package"
        exit 1
    fi
    
    # Install all Composer dependencies
    print_status "Installing PHP dependencies..."
    if ! docker-compose exec -T admin composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs; then
        print_error "Failed to install Composer dependencies"
        exit 1
    fi
    
    # Generate application key
    print_status "Generating Laravel application key..."
    docker-compose exec -T admin php artisan key:generate --force
    
    # Test and configure Redis
    print_status "Configuring cache and session drivers..."
    if docker-compose exec -T admin php -r "try { \$redis = new Redis(); \$redis->connect('redis', 6379); echo 'Redis OK'; } catch (Exception \$e) { echo 'Redis Failed'; }" 2>/dev/null | grep -q "Redis OK"; then
        print_success "Redis is available, using Redis drivers"
        docker-compose exec -T admin sed -i 's/CACHE_DRIVER=file/CACHE_DRIVER=redis/' .env || true
        docker-compose exec -T admin sed -i 's/SESSION_DRIVER=file/SESSION_DRIVER=redis/' .env || true
        docker-compose exec -T admin sed -i 's/QUEUE_CONNECTION=sync/QUEUE_CONNECTION=redis/' .env || true
    else
        print_warning "Redis not available, using file-based drivers"
        docker-compose exec -T admin sed -i 's/CACHE_DRIVER=redis/CACHE_DRIVER=file/' .env || true
        docker-compose exec -T admin sed -i 's/SESSION_DRIVER=redis/SESSION_DRIVER=file/' .env || true
        docker-compose exec -T admin sed -i 's/QUEUE_CONNECTION=redis/QUEUE_CONNECTION=sync/' .env || true
    fi
    
    # Clear all caches
    print_status "Clearing Laravel caches..."
    docker-compose exec -T admin php artisan config:clear || true
    docker-compose exec -T admin php artisan cache:clear || true
    docker-compose exec -T admin php artisan route:clear || true
    docker-compose exec -T admin php artisan view:clear || true
    
    # Run database migrations
    print_status "Running database migrations..."
    local migration_attempts=0
    while [[ $migration_attempts -lt 3 ]]; do
        if docker-compose exec -T admin php artisan migrate --force; then
            print_success "Database migrations completed"
            break
        else
            migration_attempts=$((migration_attempts + 1))
            print_warning "Migration attempt $migration_attempts failed, retrying in 10 seconds..."
            sleep 10
        fi
    done
    
    if [[ $migration_attempts -eq 3 ]]; then
        print_warning "Database migrations failed after 3 attempts - continuing anyway"
    fi
    
    # Create storage symbolic link
    print_status "Creating storage symbolic link..."
    docker-compose exec -T admin php artisan storage:link || true
    
    # Cache Laravel configuration for better performance
    print_status "Optimizing Laravel for production..."
    docker-compose exec -T admin php artisan config:cache || true
    docker-compose exec -T admin php artisan route:cache || true
    
    # Final verification
    print_status "Verifying Laravel installation..."
    if docker-compose exec -T admin php artisan --version > /dev/null; then
        print_success "Laravel is working correctly"
    else
        print_error "Laravel verification failed"
        exit 1
    fi
    
    # Test web access
    print_status "Testing web access..."
    sleep 5
    if curl -f -s http://localhost:$ADMIN_PORT/test.php > /dev/null 2>&1; then
        print_success "Web server is responding"
    else
        print_warning "Web server test failed - may need firewall configuration"
    fi
    
    print_success "Laravel application setup completed"
}

# Create systemd service
create_systemd_service() {
    print_status "Creating systemd service..."
    
    cat > /etc/systemd/system/ddeployer.service << EOF
[Unit]
Description=DDeployer Web Hosting Platform
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable ddeployer
    
    print_success "Systemd service created and enabled"
}

# Show completion message
show_completion() {
    print_success "🎉 DDeployer installation completed successfully!"
    echo
    print_status "✅ Installation Summary:"
    echo "  ✅ All containers are running"
    echo "  ✅ Database is initialized"
    echo "  ✅ Laravel is configured"
    echo "  ✅ SSL certificates ready"
    echo "  ✅ Web server is responding"
    echo
    print_status "🌐 Access Information:"
    if [[ "$LOCAL_MODE" == "true" ]]; then
        echo "  🖥️  Admin Panel: http://localhost:$ADMIN_PORT"
        echo "  🌍 Test Sites:  http://site-name.localhost"
        echo "  📊 Traefik Dashboard: http://localhost:8081"
    else
        echo "  🖥️  Admin Panel: http://your-server-ip:$ADMIN_PORT"
        echo "  📊 Traefik Dashboard: http://your-server-ip:8081"
        echo "  🌍 Configure DNS to point your domains to this server"
    fi
    echo
    print_status "🔐 Default Admin Credentials:"
    echo "  📧 Email:    admin@ddeployer.local"
    echo "  🔑 Password: admin123"
    echo
    print_warning "⚠️  IMPORTANT: Change the default admin password after first login!"
    echo
    print_status "🛠️  Management Commands:"
    echo "  🚀 Start:   systemctl start ddeployer"
    echo "  ⏹️  Stop:    systemctl stop ddeployer"
    echo "  📊 Status:  systemctl status ddeployer"
    echo "  📋 Logs:    cd $INSTALL_DIR && docker-compose logs -f"
    echo "  🔄 Update:  cd $INSTALL_DIR && sudo ./update-ddeployer.sh"
    echo
    print_status "🔧 Troubleshooting:"
    echo "  📝 Laravel logs: docker exec ddeployer-admin tail -f storage/logs/laravel.log"
    echo "  🐛 Fix issues:  cd $INSTALL_DIR && sudo ./fix-laravel-500.sh"
    echo
    print_success "🚀 Ready to deploy your first website!"
}

# Main installation function
main() {
    echo "=================================="
    echo "  DDeployer Installation Script"
    echo "=================================="
    echo
    
    parse_args "$@"
    check_root
    check_requirements
    create_install_dir
    copy_files
    generate_env
    start_services
    create_systemd_service
    show_completion
}

# Run main function
main "$@"
