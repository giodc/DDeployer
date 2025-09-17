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
    
    # Generate random passwords
    DB_PASSWORD=$(openssl rand -base64 32)
    REDIS_PASSWORD=$(openssl rand -base64 32)
    APP_KEY="base64:$(openssl rand -base64 32)"
    
    # Change to install directory to create .env file
    cd "$INSTALL_DIR"
    
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

    print_success "Environment configuration generated"
}

# Start services
start_services() {
    print_status "Starting DDeployer services..."
    
    # Change to install directory to run docker-compose
    cd "$INSTALL_DIR"
    
    docker-compose up -d
    
    # Wait for services to be ready
    print_status "Waiting for services to start..."
    sleep 30
    
    # Ensure Laravel directories exist and have proper permissions
    print_status "Setting up Laravel directories and permissions..."
    docker-compose exec -T admin mkdir -p bootstrap/cache storage/logs storage/framework/cache storage/framework/sessions storage/framework/views
    docker-compose exec -T admin chmod -R 775 bootstrap/cache storage
    docker-compose exec -T admin chown -R www-data:www-data bootstrap/cache storage
    
    # Install required Laravel UI package first
    print_status "Installing Laravel UI package..."
    if ! docker-compose exec -T admin composer require laravel/ui --no-interaction; then
        print_warning "Laravel UI package install failed, trying with --ignore-platform-reqs..."
        docker-compose exec -T admin composer require laravel/ui --no-interaction --ignore-platform-reqs
    fi
    
    # Install remaining Composer dependencies
    print_status "Installing PHP dependencies..."
    if ! docker-compose exec -T admin composer install --no-dev --optimize-autoloader --no-interaction; then
        print_warning "Composer install failed, trying with --ignore-platform-reqs..."
        docker-compose exec -T admin composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs
    fi
    
    # Generate Laravel application key
    print_status "Generating application key..."
    docker-compose exec -T admin php artisan key:generate --force
    
    # Clear and cache Laravel configuration
    print_status "Optimizing Laravel configuration..."
    docker-compose exec -T admin php artisan config:clear
    docker-compose exec -T admin php artisan cache:clear
    docker-compose exec -T admin php artisan route:clear
    docker-compose exec -T admin php artisan view:clear
    
    # Run Laravel migrations (skip if they fail)
    print_status "Setting up database..."
    if ! docker-compose exec -T admin php artisan migrate --force; then
        print_warning "Database migration failed - you may need to run migrations manually"
    fi
    
    # Skip seeding for now as we don't have seeders
    # docker-compose exec -T admin php artisan db:seed --force
    
    print_success "Services started successfully"
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
    print_success "DDeployer installation completed!"
    echo
    print_status "Access Information:"
    if [[ "$LOCAL_MODE" == "true" ]]; then
        echo "  Admin Panel: http://localhost:$ADMIN_PORT"
        echo "  Test Sites:  http://site-name.localhost"
    else
        echo "  Admin Panel: http://your-server-ip:$ADMIN_PORT"
        echo "  Configure DNS to point your domains to this server"
    fi
    echo
    print_status "Default Admin Credentials:"
    echo "  Email:    admin@ddeployer.local"
    echo "  Password: admin123"
    echo
    print_warning "Please change the default admin password after first login!"
    echo
    print_status "Useful Commands:"
    echo "  Start:   systemctl start ddeployer"
    echo "  Stop:    systemctl stop ddeployer"
    echo "  Status:  systemctl status ddeployer"
    echo "  Logs:    cd $INSTALL_DIR && docker-compose logs -f"
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
