#!/bin/bash

# DDeployer Update Script
# Safely update DDeployer from Git repository

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

# Configuration
INSTALL_DIR="/opt/ddeployer"
BACKUP_DIR="/opt/ddeployer-backup-$(date +%Y%m%d-%H%M%S)"
REPO_URL="https://github.com/giodc/ddeployer.git"

show_help() {
    cat << EOF
DDeployer Update Script

Usage: $0 [OPTIONS]

Options:
    --repo URL      Custom repository URL (default: $REPO_URL)
    --branch NAME   Specific branch to update to (default: main)
    --force         Force update even if there are local changes
    --backup-only   Only create backup, don't update
    --no-rebuild    Skip container rebuild (faster but may miss changes)
    -h, --help      Show this help message

Examples:
    $0                          # Standard update
    $0 --branch develop         # Update to develop branch
    $0 --force                  # Force update ignoring local changes
    $0 --backup-only            # Just create a backup
EOF
}

# Parse command line arguments
BRANCH="main"
FORCE_UPDATE=false
BACKUP_ONLY=false
NO_REBUILD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --repo)
            REPO_URL="$2"
            shift 2
            ;;
        --branch)
            BRANCH="$2"
            shift 2
            ;;
        --force)
            FORCE_UPDATE=true
            shift
            ;;
        --backup-only)
            BACKUP_ONLY=true
            shift
            ;;
        --no-rebuild)
            NO_REBUILD=true
            shift
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

echo "========================================"
echo "  DDeployer Update Script"
echo "========================================"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

# Check if installation directory exists
if [[ ! -d "$INSTALL_DIR" ]]; then
    print_error "DDeployer installation not found at $INSTALL_DIR"
    exit 1
fi

cd "$INSTALL_DIR"

# Check if it's a git repository
if [[ ! -d ".git" ]]; then
    print_error "DDeployer installation is not a Git repository"
    print_status "This usually means it was installed from a downloaded archive"
    print_status "To enable Git updates, you would need to:"
    print_status "  1. Backup your current installation"
    print_status "  2. Clone from Git: git clone $REPO_URL /opt/ddeployer-new"
    print_status "  3. Copy your .env and data files to the new installation"
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

# Create backup
print_status "Creating backup at $BACKUP_DIR..."
cp -r "$INSTALL_DIR" "$BACKUP_DIR"
print_success "Backup created successfully"

if [[ "$BACKUP_ONLY" == "true" ]]; then
    print_success "Backup completed. Exiting as requested."
    exit 0
fi

# Check for local changes
print_status "Checking for local changes..."
if git diff --quiet && git diff --cached --quiet; then
    print_success "No local changes detected"
else
    print_warning "Local changes detected:"
    git status --porcelain
    
    if [[ "$FORCE_UPDATE" == "false" ]]; then
        echo
        print_error "Local changes found. Options:"
        print_status "  1. Use --force to override local changes"
        print_status "  2. Commit your changes first: git add . && git commit -m 'Local changes'"
        print_status "  3. Stash your changes: git stash"
        exit 1
    else
        print_warning "Forcing update - local changes will be lost"
        git reset --hard HEAD
    fi
fi

# Fetch latest changes
print_status "Fetching latest changes from repository..."
git fetch origin

# Check if update is available
LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse origin/$BRANCH)

if [[ "$LOCAL_COMMIT" == "$REMOTE_COMMIT" ]]; then
    print_success "Already up to date!"
    exit 0
fi

print_status "Update available:"
print_status "  Current: ${LOCAL_COMMIT:0:8}"
print_status "  Latest:  ${REMOTE_COMMIT:0:8}"

# Show what will be updated
print_status "Changes to be applied:"
git log --oneline $LOCAL_COMMIT..$REMOTE_COMMIT | head -10

# Stop containers before update
print_status "Stopping DDeployer containers..."
$COMPOSE_CMD down || true

# Backup critical files that shouldn't be overwritten
print_status "Backing up critical configuration files..."
cp .env .env.backup || print_warning ".env not found"
cp admin/.env admin/.env.backup 2>/dev/null || print_warning "admin/.env not found"

# Update to latest version
print_status "Updating to latest version..."
git checkout $BRANCH
git pull origin $BRANCH

# Restore critical files
print_status "Restoring configuration files..."
if [[ -f ".env.backup" ]]; then
    cp .env.backup .env
    rm .env.backup
    print_success "Restored main .env file"
fi

if [[ -f "admin/.env.backup" ]]; then
    cp admin/.env.backup admin/.env
    rm admin/.env.backup
    print_success "Restored admin .env file"
fi

# Check if containers need rebuilding
NEEDS_REBUILD=false
if git diff --name-only $LOCAL_COMMIT $REMOTE_COMMIT | grep -E "(Dockerfile|docker-compose\.yml|requirements\.txt|composer\.json|package\.json)" > /dev/null; then
    NEEDS_REBUILD=true
    print_status "Container rebuild required due to dependency changes"
fi

if [[ "$NO_REBUILD" == "false" && "$NEEDS_REBUILD" == "true" ]]; then
    print_status "Rebuilding containers..."
    $COMPOSE_CMD build --no-cache
else
    print_status "Skipping container rebuild"
fi

# Start containers
print_status "Starting DDeployer containers..."
$COMPOSE_CMD up -d

# Wait for containers to start
print_status "Waiting for containers to start..."
sleep 30

# Run any necessary post-update tasks
print_status "Running post-update tasks..."

# Check if admin container is running and run Laravel tasks
if docker ps --format "{{.Names}}" | grep -q "ddeployer-admin"; then
    print_status "Running Laravel post-update tasks..."
    
    # Clear caches
    docker exec ddeployer-admin php artisan config:clear || true
    docker exec ddeployer-admin php artisan cache:clear || true
    docker exec ddeployer-admin php artisan route:clear || true
    docker exec ddeployer-admin php artisan view:clear || true
    
    # Run migrations
    docker exec ddeployer-admin php artisan migrate --force || print_warning "Migration failed"
    
    # Update composer dependencies if needed
    if [[ "$NEEDS_REBUILD" == "false" ]]; then
        print_status "Updating composer dependencies..."
        docker exec ddeployer-admin composer install --no-dev --optimize-autoloader --no-interaction || true
    fi
    
    print_success "Laravel post-update tasks completed"
else
    print_warning "Admin container not running - skipping Laravel tasks"
fi

# Verify update
print_status "Verifying update..."
$COMPOSE_CMD ps

NEW_COMMIT=$(git rev-parse HEAD)
if [[ "$NEW_COMMIT" == "$REMOTE_COMMIT" ]]; then
    print_success "✅ Update completed successfully!"
    print_status "Updated from ${LOCAL_COMMIT:0:8} to ${NEW_COMMIT:0:8}"
else
    print_error "❌ Update may have failed"
    print_status "Expected: ${REMOTE_COMMIT:0:8}"
    print_status "Current:  ${NEW_COMMIT:0:8}"
fi

echo
print_status "Update Summary:"
print_status "  Backup location: $BACKUP_DIR"
print_status "  Updated to commit: ${NEW_COMMIT:0:8}"
print_status "  Admin panel: http://your-server-ip:8080"
echo

print_success "🎉 DDeployer update completed!"
print_warning "If you encounter any issues, you can restore from backup:"
print_warning "  sudo rm -rf $INSTALL_DIR"
print_warning "  sudo mv $BACKUP_DIR $INSTALL_DIR"
print_warning "  cd $INSTALL_DIR && sudo $COMPOSE_CMD up -d"
echo
