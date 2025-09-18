# DDeployer Remote Installation Guide

## 🚀 One-Command Installation

DDeployer can now be installed on any fresh Ubuntu server with a single command!

## 📋 Prerequisites

- **Ubuntu 20.04+ LTS** server
- **Root access** or sudo privileges
- **Internet connection** for downloading packages
- **2GB+ RAM** recommended

## 🛠 Installation Commands

### Local Development Setup
Perfect for testing on your local machine or development server:

```bash
curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | sudo bash
```

### Production Server Setup
For production deployments with SSL support:

```bash
curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | sudo bash -s -- --production
```

### Custom Configuration
You can customize the installation with additional options:

```bash
# Custom admin port
curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | sudo bash -s -- --production --admin-port 9000

# Different repository (if you forked the project)
curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | sudo bash -s -- --repo https://github.com/yourusername/ddeployer.git
```

## 📊 What the Remote Installer Does

1. **System Check** - Verifies Ubuntu compatibility
2. **Package Updates** - Updates system packages
3. **Docker Installation** - Installs Docker and Docker Compose if needed
4. **Repository Download** - Clones DDeployer from GitHub
5. **Platform Installation** - Runs the main installer
6. **Service Setup** - Configures systemd service
7. **Cleanup** - Removes temporary files

## ⏱ Installation Time

- **Fresh Ubuntu Server**: ~5-10 minutes
- **Server with Docker**: ~2-3 minutes
- **Local Machine**: ~1-2 minutes

## 🎯 After Installation

### Access Points
- **Admin Panel**: `http://your-server-ip:8080`
- **Traefik Dashboard**: `http://your-server-ip:8081`
- **Default Login**: `admin@ddeployer.local` / `admin123`

### First Steps
1. **Login** to the admin panel
2. **Change** the default password
3. **Create** your first site
4. **Configure** DNS for production domains

## 🔧 Available Options

| Option | Description | Example |
|--------|-------------|---------|
| `--local` | Local development mode (default) | Uses .localhost domains |
| `--production` | Production server mode | Enables SSL for real domains |
| `--admin-port PORT` | Custom admin port | Default: 8080 |
| `--repo URL` | Custom repository URL | For forks or mirrors |
| `--help` | Show help message | Display all options |

## 🌐 Testing the Installation

### Local Testing
```bash
# Install locally
curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | sudo bash

# Add to /etc/hosts
echo "127.0.0.1 test.localhost" | sudo tee -a /etc/hosts

# Create a test site at http://localhost:8080
# Access it at http://test.localhost
```

### Production Testing
```bash
# Install on server
curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | sudo bash -s -- --production

# Point DNS A record to server IP
# Create site with your domain
# Access with automatic SSL
```

## 🔍 Troubleshooting

### Common Issues

**Permission Denied:**
```bash
# Make sure to use sudo
curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | sudo bash
```

**Port Already in Use:**
```bash
# Use a different port
curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | sudo bash -s -- --admin-port 9000
```

**Network Issues:**
```bash
# Check internet connection
ping github.com

# Check if GitHub is accessible
curl -I https://github.com
```

**Docker Issues:**
```bash
# Check Docker status after installation
sudo systemctl status docker
sudo docker ps
```

**Laravel Permission Issues:**
If you encounter Laravel bootstrap/cache directory errors during installation:
```bash
# Run the Laravel permissions fix script
cd /opt/ddeployer
sudo ./fix-laravel-permissions.sh
```

Common Laravel errors and solutions:
- `The /var/www/html/bootstrap/cache directory must be present and writable`
- `Auth::routes() method requires laravel/ui package`
- `Script @php artisan package:discover --ansi handling the post-autoload-dump event returned with error code 1`
- `Class "Redis" not found` - Redis PHP extension missing
- `file_get_contents(/var/www/html/.env): Failed to open stream` - Missing Laravel .env file
- `View path not found` in ViewClearCommand.php - Missing view configuration

The fix script will:
- Create required Laravel directories
- Set proper permissions (775) for bootstrap/cache and storage
- Install Laravel UI package if missing
- Create Laravel .env file if missing
- Create missing view.php configuration file
- Test Redis connectivity and configure drivers accordingly
- Clear Laravel caches with proper error handling
- Test composer install

### Manual Verification

If the remote install fails, you can verify manually:

```bash
# Check if Docker is installed
docker --version
docker-compose --version

# Check if DDeployer is running
sudo systemctl status ddeployer

# Check containers
sudo docker ps

# Check logs
cd /opt/ddeployer && sudo docker-compose logs
```

## 🚀 Advanced Usage

### Multiple Servers
You can install DDeployer on multiple servers:

```bash
# Server 1 - Development
curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | sudo bash

# Server 2 - Staging  
curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | sudo bash -s -- --production --admin-port 8080

# Server 3 - Production
curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | sudo bash -s -- --production --admin-port 8080
```

### Automation Scripts
For automated deployments:

```bash
#!/bin/bash
# deploy-ddeployer.sh

SERVERS=("server1.example.com" "server2.example.com")

for server in "${SERVERS[@]}"; do
    echo "Installing DDeployer on $server..."
    ssh root@$server "curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | bash -s -- --production"
done
```

## 📚 Next Steps

After successful installation:

1. **Read the Documentation**
   - [Installation Steps](INSTALLATION_STEPS.md)
   - [Testing Guide](TESTING.md)
   - [Deployment Guide](DEPLOYMENT_GUIDE.md)

2. **Create Your First Site**
   - Login to admin panel
   - Choose WordPress, Laravel, or PHP
   - Configure domain and SSL

3. **Explore Features**
   - Real-time monitoring
   - Log viewing
   - Performance optimization
   - Security settings

## ✅ Success Indicators

Installation is successful when:
- ✅ Admin panel loads at specified port
- ✅ You can login with default credentials
- ✅ Dashboard shows system information
- ✅ All Docker containers are running
- ✅ You can create and access test sites

**Ready to revolutionize your web hosting! 🎉**
