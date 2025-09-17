#!/bin/bash

# DDeployer Remote Installation Script
# Usage: curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/giodc/ddeployer.git"
INSTALL_DIR="/opt/ddeployer"
TEMP_DIR="/tmp/ddeployer-install"
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
            --repo)
                REPO_URL="$2"
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
    
    # Set default mode if none specified
    if [[ "$LOCAL_MODE" == "false" && "$PRODUCTION_MODE" == "false" ]]; then
        LOCAL_MODE=true
        print_warning "No mode specified, defaulting to --local"
    fi
}

show_help() {
    cat << EOF
DDeployer Remote Installation Script

Usage: curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | bash -s -- [OPTIONS]

Options:
    --local         Install for local development (default)
    --production    Install for production use
    --admin-port    Set admin panel port (default: 8080)
    --repo          Set repository URL (default: https://github.com/giodc/ddeployer.git)
    -h, --help      Show this help message

Examples:
    # Local development setup
    curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | bash
    
    # Production setup
    curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | bash -s -- --production
    
    # Custom port
    curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | bash -s -- --production --admin-port 9000
EOF
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        print_status "Run: curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | sudo bash"
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check OS
    if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
        print_warning "This installer is designed for Ubuntu. Other distributions may work but are not officially supported."
    fi
    
    # Update package list
    print_status "Updating package list..."
    apt-get update -qq
    
    # Install required packages
    print_status "Installing required packages..."
    apt-get install -y curl git wget software-properties-common apt-transport-https ca-certificates gnupg lsb-release
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_status "Installing Docker..."
        curl -fsSL https://get.docker.com | sh
        systemctl enable docker
        systemctl start docker
        
        # Add current user to docker group if not root
        if [[ -n "$SUDO_USER" ]]; then
            usermod -aG docker "$SUDO_USER"
            print_warning "User $SUDO_USER added to docker group. Please log out and back in for changes to take effect."
        fi
    else
        print_success "Docker is already installed"
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_status "Installing Docker Compose..."
        DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
        curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    else
        print_success "Docker Compose is already installed"
    fi
    
    # Verify Docker is running
    if ! docker ps &> /dev/null; then
        print_status "Starting Docker service..."
        systemctl start docker
        sleep 5
        
        if ! docker ps &> /dev/null; then
            print_error "Docker is not running. Please check Docker installation."
            exit 1
        fi
    fi
    
    # Check available ports
    if netstat -tuln 2>/dev/null | grep -q ":$ADMIN_PORT "; then
        print_error "Port $ADMIN_PORT is already in use. Please choose a different port with --admin-port"
        exit 1
    fi
}

# Download DDeployer repository
download_ddeployer() {
    print_status "Downloading DDeployer from repository..."
    
    # Clean up any existing temp directory
    rm -rf "$TEMP_DIR"
    
    # Clone repository
    if ! git clone "$REPO_URL" "$TEMP_DIR"; then
        print_error "Failed to clone repository: $REPO_URL"
        print_status "Please check if the repository URL is correct and accessible."
        exit 1
    fi
    
    print_success "DDeployer downloaded successfully"
}

# Install DDeployer
install_ddeployer() {
    print_status "Installing DDeployer..."
    
    # Change to temp directory
    cd "$TEMP_DIR"
    
    # Make install script executable
    chmod +x install.sh
    
    # Prepare install arguments
    INSTALL_ARGS=""
    if [[ "$LOCAL_MODE" == "true" ]]; then
        INSTALL_ARGS="--local"
    elif [[ "$PRODUCTION_MODE" == "true" ]]; then
        INSTALL_ARGS="--production"
    fi
    
    if [[ "$ADMIN_PORT" != "8080" ]]; then
        INSTALL_ARGS="$INSTALL_ARGS --admin-port $ADMIN_PORT"
    fi
    
    # Run the installer
    print_status "Running DDeployer installer with arguments: $INSTALL_ARGS"
    ./install.sh $INSTALL_ARGS
    
    # Clean up temp directory
    cd /
    rm -rf "$TEMP_DIR"
    
    print_success "DDeployer installation completed!"
}

# Show completion message
show_completion() {
    echo
    echo "========================================"
    echo "   DDeployer Installation Complete!"
    echo "========================================"
    echo
    print_success "🎉 DDeployer has been successfully installed!"
    echo
    print_status "Access Information:"
    if [[ "$LOCAL_MODE" == "true" ]]; then
        echo "  🌐 Admin Panel: http://localhost:$ADMIN_PORT"
        echo "  🔧 Traefik Dashboard: http://localhost:8081"
        echo "  🗄️  phpMyAdmin: http://localhost/phpmyadmin"
        echo "  📊 Redis Commander: http://localhost/redis"
        echo
        echo "  🏠 For local development, add to /etc/hosts:"
        echo "     127.0.0.1 mysite.localhost"
    else
        echo "  🌐 Admin Panel: http://your-server-ip:$ADMIN_PORT"
        echo "  🔧 Traefik Dashboard: http://your-server-ip:8081"
        echo "  📋 Configure DNS to point your domains to this server"
    fi
    echo
    print_status "🔐 Default Admin Credentials:"
    echo "  📧 Email:    admin@ddeployer.local"
    echo "  🔑 Password: admin123"
    echo
    print_warning "⚠️  Please change the default admin password after first login!"
    echo
    print_status "🛠️  Useful Commands:"
    echo "  ▶️  Start:   systemctl start ddeployer"
    echo "  ⏹️  Stop:    systemctl stop ddeployer"
    echo "  📊 Status:  systemctl status ddeployer"
    echo "  📝 Logs:    cd $INSTALL_DIR && docker-compose logs -f"
    echo
    print_status "📚 Documentation:"
    echo "  📖 Installation Guide: $INSTALL_DIR/INSTALLATION_STEPS.md"
    echo "  🧪 Testing Guide: $INSTALL_DIR/TESTING.md"
    echo "  🚀 Deployment Guide: $INSTALL_DIR/DEPLOYMENT_GUIDE.md"
    echo
    print_success "🚀 Ready to deploy your first site!"
    echo
}

# Main installation function
main() {
    echo "========================================"
    echo "  DDeployer Remote Installation Script"
    echo "========================================"
    echo
    
    parse_args "$@"
    check_root
    check_requirements
    download_ddeployer
    install_ddeployer
    show_completion
}

# Handle script interruption
trap 'print_error "Installation interrupted. Cleaning up..."; rm -rf "$TEMP_DIR"; exit 1' INT TERM

# Run main function with all arguments
main "$@"
