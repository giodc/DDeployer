# DDeployer Quick Start Guide

## 🚀 Quick Installation Steps

### 1. Verify You're in the Right Directory

First, make sure you're in the DDeployer directory and all files are present:

```bash
# Navigate to the DDeployer directory
cd /Users/giovannidecarlo/Documents/Development/Projects/DDeployer

# Run the test script to verify files
./test-install.sh
```

You should see all files marked with ✓. If any files are missing (✗), the installation won't work.

### 2. Run the Installation

Once all files are verified:

```bash
# For local development (recommended for testing)
sudo ./install.sh --local

# OR for production
sudo ./install.sh --production
```

### 3. Troubleshooting Common Issues

#### Issue: "Application files not found"
**Solution:** Make sure you're running the installer from the DDeployer directory:
```bash
cd /Users/giovannidecarlo/Documents/Development/Projects/DDeployer
pwd  # Should show the DDeployer path
ls   # Should show install.sh, docker-compose.yml, admin/, etc.
sudo ./install.sh --local
```

#### Issue: "Docker already installed" message
This is normal and not an error. The installer detects existing Docker and continues.

#### Issue: Permission denied
Make sure the script is executable:
```bash
chmod +x install.sh
chmod +x test-install.sh
```

### 4. What the Installer Does

1. **Checks requirements** (Docker, Docker Compose)
2. **Creates installation directory** (`/opt/ddeployer`)
3. **Copies application files** from your current directory
4. **Generates secure passwords** and configuration
5. **Starts all services** (Traefik, MariaDB, Redis, Admin Panel)
6. **Creates systemd service** for auto-start

### 5. Expected Output

You should see output like:
```
==================================
  DDeployer Installation Script
==================================

[INFO] Checking system requirements...
[SUCCESS] Docker is already installed
[SUCCESS] Docker Compose is already installed
[INFO] Creating installation directory: /opt/ddeployer
[INFO] Copying application files...
[INFO] Found application files in: /path/to/DDeployer
[INFO] Generating environment configuration...
[INFO] Starting DDeployer services...
[INFO] Setting up database...
[SUCCESS] Services started successfully
[SUCCESS] DDeployer installation completed!
```

### 6. Access After Installation

- **Admin Panel**: http://localhost:8080
- **Login**: admin@ddeployer.local / admin123
- **Traefik Dashboard**: http://localhost:8081

### 7. Create Your First Site

1. Login to admin panel
2. Go to "Sites" → "Create New Site"
3. Choose WordPress, Laravel, or PHP
4. Add domain (use `.localhost` for local testing)
5. Enable database if needed
6. Click "Create Site"

### 8. Test Site Access

For local development, add to `/etc/hosts`:
```
127.0.0.1 mysite.localhost
127.0.0.1 wordpress.localhost
127.0.0.1 laravel.localhost
```

Then access: http://mysite.localhost

## 🆘 Still Having Issues?

1. **Run the test script first**: `./test-install.sh`
2. **Check you're in the right directory**: `pwd` should show DDeployer path
3. **Verify file permissions**: `ls -la install.sh` should show executable permissions
4. **Check Docker is running**: `docker ps` should work without errors

## 📝 Manual Verification

If the installer still fails, you can manually verify the setup:

```bash
# Check current directory
pwd

# List files (should show docker-compose.yml, admin/, etc.)
ls -la

# Check Docker
docker --version
docker-compose --version

# Check permissions
ls -la install.sh
```

The installer should work if:
- ✅ You're in the DDeployer directory
- ✅ All required files are present
- ✅ Docker and Docker Compose are installed
- ✅ You're running with sudo privileges
