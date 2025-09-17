# DDeployer - Step-by-Step Installation Guide

## 🚀 Complete Installation Instructions

### Step 1: Verify Prerequisites

**Run the verification script first:**
```bash
cd /Users/giovannidecarlo/Documents/Development/Projects/DDeployer
./verify-setup.sh
```

This will check:
- ✅ All required files are present
- ✅ Docker and Docker Compose are installed
- ✅ Ports are available
- ✅ System resources are sufficient

### Step 2: Choose Installation Mode

**For Local Development (Recommended for Testing):**
```bash
sudo ./install.sh --local
```

**For Production Server:**
```bash
sudo ./install.sh --production
```

### Step 3: Installation Process

The installer will:

1. **Check Requirements** - Verify Docker installation
2. **Create Directory** - Set up `/opt/ddeployer`
3. **Copy Files** - Transfer all application files
4. **Generate Config** - Create secure passwords and settings
5. **Start Services** - Launch all Docker containers
6. **Setup Database** - Initialize admin database
7. **Create Service** - Add systemd service for auto-start

**Expected Output:**
```
==================================
  DDeployer Installation Script
==================================

[INFO] Checking system requirements...
[SUCCESS] Docker is already installed
[SUCCESS] Docker Compose is already installed
[INFO] Creating installation directory: /opt/ddeployer
[INFO] Copying application files...
[SUCCESS] Found application files in: /path/to/DDeployer
[INFO] Generating environment configuration...
[INFO] Starting DDeployer services...
[INFO] Waiting for services to start...
[INFO] Setting up database...
[SUCCESS] Services started successfully
[SUCCESS] DDeployer installation completed!
```

### Step 4: Access the Platform

**Admin Panel:** http://localhost:8080

**Default Login:**
- Email: `admin@ddeployer.local`
- Password: `admin123`

**Other Services:**
- Traefik Dashboard: http://localhost:8081
- phpMyAdmin: http://localhost/phpmyadmin
- Redis Commander: http://localhost/redis

### Step 5: Create Your First Site

1. **Login** to the admin panel
2. **Navigate** to Sites → Create New Site
3. **Choose** site type:
   - **WordPress** - Full CMS with caching
   - **Laravel** - PHP framework with queues
   - **PHP** - Generic PHP application

4. **Configure** site settings:
   - **Name**: `my-test-site`
   - **Domain**: `test.localhost` (for local)
   - **Database**: Enable if needed
   - **SSL**: Enable for production domains
   - **Caching**: Enable for better performance

5. **Create** the site and wait for deployment

### Step 6: Test Site Access

**For Local Development:**
Add to `/etc/hosts`:
```
127.0.0.1 test.localhost
127.0.0.1 wordpress.localhost
127.0.0.1 laravel.localhost
```

Then visit: http://test.localhost

**For Production:**
Point your domain's DNS A record to your server's IP address.

## 🔧 System Management

### Service Control
```bash
# Start DDeployer
sudo systemctl start ddeployer

# Stop DDeployer
sudo systemctl stop ddeployer

# Check status
sudo systemctl status ddeployer

# View logs
cd /opt/ddeployer && docker-compose logs -f
```

### Site Management
```bash
# List running containers
docker ps

# View site logs
docker logs site-name

# Restart site
docker-compose -f /opt/ddeployer/data/sites/site-name/docker-compose.yml restart
```

## 🛠 Troubleshooting

### Common Issues

**1. "Application files not found"**
```bash
# Ensure you're in the DDeployer directory
cd /Users/giovannidecarlo/Documents/Development/Projects/DDeployer
pwd  # Should show DDeployer path
ls   # Should show install.sh, docker-compose.yml, etc.
```

**2. "Port already in use"**
```bash
# Check what's using the port
sudo lsof -i :8080
# Stop the conflicting service or change the port
sudo ./install.sh --local --admin-port 9080
```

**3. "Docker daemon not running"**
```bash
# Start Docker
sudo systemctl start docker
# Or on macOS
open -a Docker
```

**4. "Permission denied"**
```bash
# Make scripts executable
chmod +x install.sh verify-setup.sh test-install.sh
```

**5. Site not accessible**
```bash
# Check container status
docker ps --filter "name=site-"

# Check Traefik logs
docker logs ddeployer-traefik

# Verify DNS (for production)
nslookup yourdomain.com
```

### Log Locations
- **Admin Panel**: `docker logs ddeployer-admin`
- **Traefik**: `docker logs ddeployer-traefik`
- **Database**: `docker logs ddeployer-mariadb`
- **Site Logs**: `docker logs site-name`

## 📊 Performance Optimization

### Recommended Settings
- **Memory**: 4GB+ RAM for multiple sites
- **Storage**: SSD recommended for database performance
- **Network**: Stable internet for SSL certificate generation

### Monitoring
- Use the admin dashboard for real-time monitoring
- Check system resources regularly
- Monitor container logs for errors

## 🔒 Security

### Initial Security Steps
1. **Change default admin password** immediately
2. **Enable SSL** for all production domains
3. **Keep system updated**: `sudo apt update && sudo apt upgrade`
4. **Monitor access logs** regularly

### Backup Strategy
```bash
# Backup entire installation
sudo tar -czf ddeployer-backup-$(date +%Y%m%d).tar.gz /opt/ddeployer/

# Backup specific site
sudo tar -czf site-backup.tar.gz /opt/ddeployer/data/sites/site-name/
```

## 🚀 Next Steps

1. **Explore the Admin Panel** - Familiarize yourself with all features
2. **Create Test Sites** - Try different application types
3. **Configure DNS** - Set up your domains for production
4. **Set Up Monitoring** - Monitor performance and logs
5. **Plan Backups** - Implement regular backup strategy

## 📞 Support

If you encounter issues:
1. **Check logs** first using the commands above
2. **Run verification script** to check system state
3. **Review this guide** for common solutions
4. **Check system resources** (memory, disk space)

## ✅ Success Indicators

You'll know the installation is successful when:
- ✅ Admin panel loads at http://localhost:8080
- ✅ You can login with default credentials
- ✅ Dashboard shows system information
- ✅ You can create and access test sites
- ✅ All Docker containers are running (`docker ps`)

**Congratulations! Your DDeployer platform is ready! 🎉**
