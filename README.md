# 🚀 Infrastructure Stack

A comprehensive Docker-based infrastructure stack with automatic SSL, reverse proxy, and enterprise-grade services for development and production environments.

## 📋 Table of Contents

- [Overview](#overview)
- [Services](#services)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [SSL Certificates](#ssl-certificates)
- [Deployment](#deployment)
- [Management](#management)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🎯 Overview

This infrastructure stack provides a complete development and production environment with:

- **🔒 Automatic SSL/TLS** with Let's Encrypt and mkcert
- **🌐 Reverse Proxy** with Caddy for seamless routing
- **📊 Database Management** with CloudBeaver
- **🖥️ Device Management** with Fleet
- **📈 Analytics** with Tinybird
- **🗄️ Multi-Database Support** (MySQL, PostgreSQL, Redis)
- **🔄 Enhanced Backup & Restore** with S3 integration
- **☁️ AWS CLI Auto-Installation** for seamless cloud backups
- **📝 Comprehensive Logging** and monitoring

## 🛠️ Services

| Service | Description | Local URL | Production URL |
|---------|-------------|-----------|----------------|
| **Caddy** | Reverse Proxy & SSL Termination | `localhost:8080` | `yourdomain.com` |
| **Fleet** | Device Management Platform | `https://fleet.localhost` | `https://fleet.yourdomain.com` |
| **CloudBeaver** | Database Management UI | `https://cb.localhost` | `https://cb.yourdomain.com` |
| **Tinybird** | Real-time Analytics | `https://tb.localhost` | `https://tb.yourdomain.com` |
| **MySQL** | Primary Database | `mysql.localhost:13502` | `mysql.yourdomain.com` |
| **PostgreSQL** | Secondary Database | `postgres.localhost:13504` | `postgres.yourdomain.com` |
| **Redis** | Cache & Session Store | `redis.localhost:13500` | `redis.yourdomain.com` |

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Git
- Domain name (for production)
- Cloudflare account (for production SSL)
- AWS CLI (auto-installed if needed for S3 backups)

### 1. Clone & Setup

```bash
git clone <your-repo-url>
cd infra
cp env.example .env
```

### 2. Configure Environment

Edit `.env` file with your settings:

```bash
# Basic Configuration
EMAIL=your-email@domain.com
DOMAIN=yourdomain.com
DEPLOYMENT_ENV=production

# SSL Configuration
SSL_COUNTRY=US
SSL_STATE=California
SSL_CITY=San Francisco
SSL_ORG="Your Company"
SSL_PREFIX=your-company

# Database Passwords
MYSQL_ROOT_PASSWORD=your_secure_mysql_password
FLEET_MYSQL_PASSWORD=your_secure_fleet_password
POSTGRES_PASSWORD=your_secure_postgres_password
REDIS_PASSWORD=your_secure_redis_password

# Cloudflare (for production)
CLOUDFLARE_API_TOKEN=your_cloudflare_token
```

### 3. Deploy

#### Local Development
```bash
./infra.sh
# Choose option 8: Setup localhost infrastructure
```

#### Production
```bash
./infra.sh
# Choose option 9: Setup production infrastructure
```

### 4. Access Services

- **Fleet**: https://fleet.localhost (or https://fleet.yourdomain.com)
- **CloudBeaver**: https://cb.localhost (or https://cb.yourdomain.com)
- **Tinybird**: https://tb.localhost (or https://tb.yourdomain.com)
- **Health Check**: https://localhost:8080/health

## ⚙️ Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `EMAIL` | Admin email for SSL certificates | - | ✅ |
| `DOMAIN` | Your domain name | localhost | ✅ (production) |
| `DEPLOYMENT_ENV` | Environment (local/production) | local | ✅ |
| `DOCKER_NETWORK` | Docker network name | my-network | ❌ |
| `CLOUDBEAVER_PLATFORM` | CloudBeaver platform (auto-detected) | linux/amd64 | ❌ |
| `MYSQL_ROOT_PASSWORD` | MySQL root password | - | ✅ |
| `FLEET_MYSQL_PASSWORD` | Fleet MySQL password | - | ✅ |
| `POSTGRES_PASSWORD` | PostgreSQL password | - | ✅ |
| `REDIS_PASSWORD` | Redis password | - | ✅ |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token | - | ✅ (production) |
| `S3_BACKUP_ENABLED` | Enable S3 backup uploads | false | ❌ |
| `S3_BUCKET_NAME` | S3 bucket for backups | - | ✅ (if S3 enabled) |
| `S3_REGION` | AWS region for S3 | - | ✅ (if S3 enabled) |
| `S3_ACCESS_KEY_ID` | AWS access key ID | - | ✅ (if S3 enabled) |
| `S3_SECRET_ACCESS_KEY` | AWS secret access key | - | ✅ (if S3 enabled) |
| `S3_ENDPOINT_URL` | S3 endpoint URL | https://s3.amazonaws.com | ❌ |

### SSL Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `SSL_COUNTRY` | SSL certificate country | IN |
| `SSL_STATE` | SSL certificate state | Rajasthan |
| `SSL_CITY` | SSL certificate city | Jaipur |
| `SSL_ORG` | SSL certificate organization | Your Company |
| `SSL_PREFIX` | SSL certificate prefix | your-company |

## 🔐 SSL Certificates

### Local Development (mkcert)
- **Automatic localhost certificates** with mkcert
- **No browser warnings** for local development
- **Self-signed certificates** for internal services

### Production (Let's Encrypt)
- **Automatic SSL certificates** via Let's Encrypt
- **Cloudflare DNS challenge** for wildcard certificates
- **Automatic renewal** handled by Caddy

### Internal Services
- **MySQL**: Internal SSL certificates
- **PostgreSQL**: Internal SSL certificates  
- **Redis**: Internal SSL certificates

### AWS CLI Auto-Installation
- **Automatic detection**: Checks if AWS CLI is installed during S3 backups
- **Multi-platform support**: Ubuntu/Debian, CentOS/RHEL, macOS, and pip fallback
- **Zero configuration**: Installs automatically when needed
- **Manual installation**: Available via menu option 7

### Platform Compatibility
- **Automatic platform detection**: Detects system architecture (x86_64, ARM64, ARMv7)
- **Cross-platform support**: Works on Ubuntu servers (x86_64) and ARM-based systems
- **CloudBeaver compatibility**: Automatically sets correct platform for CloudBeaver
- **Docker multi-arch**: Supports both AMD64 and ARM64 architectures

## 🚀 Deployment

### Local Development

```bash
# Setup localhost environment
./infra.sh
# Choose option 7

# Start services
docker compose up -d

# Check status
docker compose ps
```

### Production Deployment

```bash
# Setup production environment
./infra.sh
# Choose option 8

# Deploy with your domain
./infra.sh
# Enter your domain and email when prompted

# Start services
docker compose up -d
```

### Individual Service Deployment

```bash
# Deploy specific service
./infra.sh
# Choose option 9: Deploy individual service
```

## 🛠️ Management

### Infrastructure CLI

The `infra.sh` script provides a comprehensive management interface:

```bash
./infra.sh
```

**Available Options:**
1. 🐳 Install Docker
2. 👤 Add Docker User
3. 🔍 Check Docker User
4. 🔍 Check Docker
5. 📋 List Docker Services
6. 🧹 Clean Everything Docker
7. ☁️ Install AWS CLI
8. 🚀 Setup localhost infrastructure
9. 🚀 Setup production infrastructure
10. 🎯 Deploy individual service
11. ▶️ Start All Services
12. 🛑 Stop All Services
13. 🔄 Restart All Services
14. 📊 Check Service Status
15. 📋 View Service Logs
16. 📊 System Overview
17. 💾 Memory Usage
18. 🖥️ CPU Usage
19. 💿 Disk Usage
20. 📊 Backup All Databases
21. 🐘 Backup MySQL Only
22. 🐘 Backup PostgreSQL Only
23. 🔴 Backup Redis Only
24. 📊 Backup ClickHouse Only
25. 🔄 Restore Database
26. 📋 List Available Backups
27. ⏰ Setup Automated Backups (Cron)
28. 🧪 Test Backup System
29. 📊 Backup Status & Info
30. 🧹 Cleanup Old Backups
31. 🗑️ Remove Automated Backups
32. ⏰ Setup Cleanup Cron (Local & S3)
33. 🔧 Setup mkcert SSL (No Browser Warnings)
34. 🔍 Check SSL Certificates
35. 🔥 Firewall Status
36. 📋 List All Cron Jobs
37. 💾 Save Cron Jobs to File
38. 📥 Restore Cron Jobs from File
39. 🗑️ Remove All Cron Jobs
40. 🧹 Remove Backup Cron Jobs Only
41. 🔧 Edit Cron Jobs Manually
42. 📄 View Cron Logs
43. 🗑️ Remove Cron Logs
44. 🧹 Clean Old Cron Logs
45. ❓ Help
46. 🚪 Exit

### Docker Compose Commands

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f

# Restart specific service
docker compose restart fleet

# Check status
docker compose ps
```

### Backup & Restore

```bash
# Create backup
./infra.sh
# Choose option 20: Backup All Databases

# Restore from backup
./infra.sh
# Choose option 25: Restore Database

# Test backup system
./infra.sh
# Choose option 28: Test Backup System

# Setup automated backups
./infra.sh
# Choose option 27: Setup Automated Backups (Cron)
```

### Enhanced Backup Features

- **🔄 Automatic S3 Upload**: Backups automatically uploaded to S3 when enabled
- **☁️ AWS CLI Auto-Install**: Automatically installs AWS CLI if missing
- **📅 Organized Storage**: Backups organized by date in S3
- **🧹 Automatic Cleanup**: Old backups cleaned up automatically
- **🔍 Backup Testing**: Built-in backup system testing
- **📊 Backup Statistics**: Detailed backup status and information

### AWS CLI & S3 Backups

```bash
# Install AWS CLI
./infra.sh
# Choose option 7: Install AWS CLI

# Configure AWS credentials
aws configure
# Or set environment variables:
# export AWS_ACCESS_KEY_ID=your_access_key
# export AWS_SECRET_ACCESS_KEY=your_secret_key
# export AWS_DEFAULT_REGION=your_region

# Test AWS connection
aws sts get-caller-identity
```

## 🔧 Troubleshooting

### Common Issues

#### 1. 502 Bad Gateway
```bash
# Check service status
docker compose ps

# Check logs
docker compose logs fleet
docker compose logs caddy

# Restart services
docker compose restart
```

#### 2. SSL Certificate Issues
```bash
# Regenerate SSL certificates
./infra.sh
# Choose option 15: Generate SSL certificates

# Setup mkcert for localhost
./infra.sh
# Choose option 19: Setup mkcert SSL
```

#### 3. Network Issues
```bash
# Check Docker networks
docker network ls

# Remove conflicting networks
docker network rm infra_my-network

# Restart with clean networks
docker compose down
docker compose up -d
```

#### 4. Database Connection Issues
```bash
# Check database logs
docker compose logs mysql
docker compose logs postgres
docker compose logs redis

# Verify database health
docker compose exec mysql mysqladmin ping -h localhost -u root -p
docker compose exec postgres pg_isready -U postgres
docker compose exec redis redis-cli ping
```

#### 5. AWS CLI & S3 Backup Issues
```bash
# Check if AWS CLI is installed
aws --version

# Install AWS CLI if missing
./infra.sh
# Choose option 7: Install AWS CLI

# Test AWS credentials
aws sts get-caller-identity

# Test S3 access
aws s3 ls s3://your-bucket-name

# Check S3 backup configuration
grep S3_ .env

# Manual S3 backup test
aws s3 cp test-file.txt s3://your-bucket-name/test/
```

#### 6. Platform Compatibility Issues
```bash
# Check system architecture
uname -m

# Check Docker platform support
docker info | grep -E "(Architecture|Platform)"

# Test platform detection
source scripts/core.sh && detect_platform

# Manual platform override (if needed)
export CLOUDBEAVER_PLATFORM=linux/amd64  # For Ubuntu servers
export CLOUDBEAVER_PLATFORM=linux/arm64  # For ARM systems

# Rebuild CloudBeaver with correct platform
docker compose up -d --force-recreate cloudbeaver
```

### Logs

```bash
# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f fleet
docker compose logs -f caddy
docker compose logs -f mysql

# View infrastructure logs
tail -f logs/infrastructure_$(date +%Y%m%d).log
```

### Health Checks

```bash
# Check service health
curl -k https://localhost:8080/health

# Check Fleet
curl -k -I https://fleet.localhost

# Check CloudBeaver
curl -k -I https://cb.localhost

# Check Tinybird
curl -k -I https://tb.localhost
```

## 📁 Project Structure

```
infra/
├── 📄 README.md                 # This file
├── 🐳 docker-compose.yml       # Docker services configuration
├── 🌐 Caddyfile                # Reverse proxy configuration
├── ⚙️ env.example              # Environment variables template
├── 🚀 infra.sh                 # Main management script
├── 📁 scripts/                 # Management scripts
│   ├── 🔧 core.sh              # Core functions
│   ├── 🛠️ services.sh          # Service management
│   ├── 💾 backup.sh            # Backup functions
│   ├── 📥 restore.sh           # Restore functions
│   ├── 🗑️ remove.sh            # Cleanup functions
│   ├── ⏰ cron.sh              # Cron job management
│   ├── 📝 logs.sh              # Logging functions
│   └── 🚀 setup.sh             # Setup functions
├── 📁 ssl/                     # SSL certificates
│   ├── 📁 mkcert/              # Localhost certificates
│   ├── 📁 localhost-ca/        # Localhost CA
│   ├── 📁 mysql/               # MySQL SSL certificates
│   ├── 📁 postgres/            # PostgreSQL SSL certificates
│   └── 📁 redis/               # Redis SSL certificates
└── 📁 logs/                    # Application logs
    └── 📄 infrastructure_*.log # Infrastructure logs
```

## 🔒 Security

### Production Security Features

- **🔐 Automatic SSL/TLS** with Let's Encrypt
- **🛡️ Security Headers** (HSTS, CSP, X-Frame-Options)
- **🔒 Internal SSL** for database communications
- **🌐 Cloudflare Integration** for DDoS protection
- **🔑 Secure Password Management** via environment variables
- **🚫 Server Header Removal** for security through obscurity

### Security Headers

```http
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
```

## 📊 Monitoring

### Health Checks

All services include health checks:

- **MySQL**: `mysqladmin ping`
- **PostgreSQL**: `pg_isready`
- **Redis**: `redis-cli ping`
- **CloudBeaver**: HTTP status check
- **Fleet**: HTTP status check

### Logging

- **Structured logging** with timestamps
- **Service-specific logs** in Caddy
- **Infrastructure logs** in `logs/` directory
- **Docker logs** accessible via `docker compose logs`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **🐛 Issues**: [GitHub Issues](https://github.com/jsharma44/infra-cli/issues)

## 🙏 Acknowledgments

- [Fleet](https://fleetdm.com/) - Device management platform
- [CloudBeaver](https://cloudbeaver.io/) - Database management
- [Tinybird](https://www.tinybird.co/) - Real-time analytics
- [Caddy](https://caddyserver.com/) - Reverse proxy and SSL
- [Docker](https://www.docker.com/) - Containerization platform

---

