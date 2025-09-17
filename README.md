# DDeployer - Docker Web Hosting Platform

A high-performance Docker-based web hosting platform with automatic SSL, caching, and multi-site management.

## Features

- 🚀 **High Performance**: FrankenPHP + Caddy + Redis caching
- 🔒 **Automatic SSL**: Let's Encrypt integration via Traefik
- 🌐 **Multi-Site Support**: WordPress, Laravel, and PHP applications
- 📊 **Web Admin Panel**: Laravel-based management interface
- 🐳 **Docker Native**: Full containerization with Docker Compose
- ⚡ **Optimized Stack**: Redis caching, database optimization

## Supported Applications

- **WordPress**: Full WordPress deployment with caching
- **Laravel**: Laravel applications with queue support
- **PHP**: Generic PHP applications

## Quick Installation

### Remote Installation (Recommended)

```bash
# Local development setup
curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | sudo bash

# Production setup
curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | sudo bash -s -- --production

# Custom port
curl -sSL https://raw.githubusercontent.com/giodc/ddeployer/main/remote-install.sh | sudo bash -s -- --production --admin-port 9000
```

### Manual Installation

```bash
git clone https://github.com/giodc/ddeployer.git
cd ddeployer
chmod +x install.sh
sudo ./install.sh --local
```

## Architecture

- **Traefik**: Reverse proxy with automatic SSL
- **FrankenPHP**: High-performance PHP runtime
- **Redis**: Caching layer
- **MariaDB**: Database server
- **Laravel Admin**: Web management interface

## Usage

1. Access admin panel at `http://your-server:8080`
2. Add new sites through the web interface
3. Configure domains and SSL automatically
4. Monitor performance and manage deployments

## Requirements

- Ubuntu 20.04+ LTS
- Docker & Docker Compose
- 2GB+ RAM recommended
- Domain names (for SSL)

## Testing

### Local Testing
```bash
# Start with local domains
./install.sh --local

# Access admin at http://localhost:8080
# Test sites at http://site1.localhost
```

### Production Testing
```bash
# Install on server
./install.sh --production

# Configure DNS to point to server
# Access admin at https://your-domain:8080
```

## Performance Features

- **FrankenPHP**: Modern PHP runtime with built-in server
- **Redis Caching**: Object and page caching
- **Optimized Images**: Lightweight Docker containers
- **CDN Ready**: Traefik integration for edge caching

## Security

- Automatic SSL certificate management
- Container isolation
- Secure database connections
- Regular security updates

## License

MIT License
