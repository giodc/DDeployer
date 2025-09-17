# DDeployer Testing Guide

This guide explains how to test the DDeployer platform locally and on production servers.

## Prerequisites

- Docker and Docker Compose installed
- Ubuntu 20.04+ LTS (for production)
- At least 2GB RAM
- Domain names (for SSL testing)

## Local Testing

### 1. Quick Local Setup

```bash
# Clone the repository
git clone <repository-url>
cd DDeployer

# Make installer executable
chmod +x install.sh

# Install for local development
sudo ./install.sh --local
```

### 2. Access the Platform

After installation:
- **Admin Panel**: http://localhost:8080
- **Traefik Dashboard**: http://localhost:8081
- **phpMyAdmin**: http://localhost/phpmyadmin
- **Redis Commander**: http://localhost/redis

### 3. Default Credentials

```
Email: admin@ddeployer.local
Password: admin123
```

### 4. Create Test Sites

#### WordPress Site
1. Go to Sites → Create New Site
2. Name: `test-wordpress`
3. Type: WordPress
4. Domain: `wordpress.localhost`
5. Enable database creation
6. Click "Create Site"

#### Laravel Site
1. Go to Sites → Create New Site
2. Name: `test-laravel`
3. Type: Laravel
4. Domain: `laravel.localhost`
5. Enable database and caching
6. Click "Create Site"

#### PHP Site
1. Go to Sites → Create New Site
2. Name: `test-php`
3. Type: PHP
4. Domain: `php.localhost`
5. Click "Create Site"

### 5. Test Site Access

After creating sites, they should be accessible at:
- http://wordpress.localhost
- http://laravel.localhost
- http://php.localhost

## Production Testing

### 1. Server Setup

```bash
# On Ubuntu server
sudo apt update && sudo apt upgrade -y

# Clone repository
git clone <repository-url>
cd DDeployer

# Install for production
sudo ./install.sh --production
```

### 2. DNS Configuration

Point your domains to the server IP:
```
A    example.com        → YOUR_SERVER_IP
A    www.example.com    → YOUR_SERVER_IP
A    app.example.com    → YOUR_SERVER_IP
```

### 3. Create Production Sites

#### WordPress with SSL
1. Create site with domain: `blog.example.com`
2. Enable SSL (Let's Encrypt)
3. Enable caching
4. Test at: https://blog.example.com

#### Laravel Application
1. Create site with domain: `app.example.com`
2. Enable SSL and caching
3. Upload Laravel application files
4. Test at: https://app.example.com

### 4. SSL Testing

Test SSL certificates:
```bash
# Check SSL certificate
curl -I https://your-domain.com

# Test SSL Labs rating
# Visit: https://www.ssllabs.com/ssltest/
```

## Performance Testing

### 1. Load Testing

```bash
# Install Apache Bench
sudo apt install apache2-utils

# Test site performance
ab -n 1000 -c 10 http://your-site.localhost/

# Test with SSL
ab -n 1000 -c 10 https://your-site.com/
```

### 2. Cache Testing

```bash
# Test Redis cache
docker exec ddeployer-redis redis-cli ping

# Monitor cache usage
docker exec ddeployer-redis redis-cli info memory
```

### 3. Database Performance

```bash
# Check database performance
docker exec ddeployer-mariadb mysql -u root -p -e "SHOW PROCESSLIST;"

# Check slow queries
docker exec ddeployer-mariadb mysql -u root -p -e "SHOW VARIABLES LIKE 'slow_query_log';"
```

## Monitoring and Logs

### 1. Container Status

```bash
# Check all containers
docker ps

# Check specific site
docker ps --filter "name=site-"

# View container logs
docker logs site-1-test-wordpress
```

### 2. System Monitoring

```bash
# Check system resources
htop

# Check disk usage
df -h

# Check memory usage
free -h

# Check Docker usage
docker system df
```

### 3. Application Logs

```bash
# Admin panel logs
docker logs ddeployer-admin

# Traefik logs
docker logs ddeployer-traefik

# Database logs
docker logs ddeployer-mariadb
```

## Troubleshooting

### Common Issues

#### 1. Site Not Accessible
```bash
# Check container status
docker ps --filter "name=your-site"

# Check Traefik configuration
docker logs ddeployer-traefik

# Verify DNS resolution
nslookup your-domain.com
```

#### 2. SSL Certificate Issues
```bash
# Check certificate status
docker logs ddeployer-traefik | grep -i "certificate"

# Manual certificate request
docker exec ddeployer-traefik traefik version
```

#### 3. Database Connection Issues
```bash
# Check database container
docker logs site-name-db

# Test database connection
docker exec site-name-db mysql -u username -p -e "SELECT 1;"
```

#### 4. Performance Issues
```bash
# Check resource usage
docker stats

# Check cache status
docker exec site-name-redis redis-cli info stats

# Optimize database
docker exec site-name-db mysql -u root -p -e "OPTIMIZE TABLE database_name.*;"
```

## Backup and Recovery

### 1. Site Backup

```bash
# Backup site files
tar -czf site-backup.tar.gz /opt/ddeployer/data/sites/site-name/

# Backup database
docker exec site-name-db mysqldump -u root -p database_name > backup.sql
```

### 2. Full System Backup

```bash
# Backup entire DDeployer installation
tar -czf ddeployer-backup.tar.gz /opt/ddeployer/

# Backup Docker volumes
docker run --rm -v ddeployer_mysql_data:/data -v $(pwd):/backup alpine tar czf /backup/mysql-backup.tar.gz /data
```

### 3. Recovery

```bash
# Restore site files
tar -xzf site-backup.tar.gz -C /

# Restore database
docker exec -i site-name-db mysql -u root -p database_name < backup.sql
```

## Security Testing

### 1. Security Scan

```bash
# Install security tools
sudo apt install nmap nikto

# Port scan
nmap -sS -O your-server-ip

# Web vulnerability scan
nikto -h http://your-site.com
```

### 2. SSL Security

```bash
# Test SSL configuration
testssl.sh https://your-site.com

# Check certificate chain
openssl s_client -connect your-site.com:443 -showcerts
```

## Cleanup

### 1. Remove Test Sites

```bash
# Through admin panel
# Go to Sites → Select site → Delete

# Manual cleanup
docker-compose -f /opt/ddeployer/data/sites/site-name/docker-compose.yml down -v
rm -rf /opt/ddeployer/data/sites/site-name/
```

### 2. System Cleanup

```bash
# Clean Docker system
docker system prune -a

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune
```

## Support

For issues and support:
1. Check logs first
2. Verify configuration
3. Test with minimal setup
4. Check GitHub issues
5. Create detailed bug report

## Performance Benchmarks

Expected performance metrics:
- **Response Time**: < 200ms (cached)
- **Throughput**: 1000+ req/sec (simple pages)
- **Memory Usage**: < 512MB per site
- **CPU Usage**: < 50% under normal load
