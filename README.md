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

The infrastructure uses a centralized environment management system with `env.sh`:

- **🔧 Centralized Loading**: All environment variables loaded from `scripts/env.sh`
- **🔄 No Circular Dependencies**: Smart loading prevents dependency loops
- **📤 Automatic Export**: Variables automatically exported for child processes
- **🛡️ Multi-line Support**: Handles complex variables like SSL certificates
- **🎯 Consistent Access**: All scripts use the same environment source

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
# Choose option 10: Setup localhost infrastructure
```

#### Production
```bash
./infra.sh
# Choose option 11: Setup production infrastructure
```

### 4. Access Services

- **Fleet**: https://fleet.localhost (or https://fleet.yourdomain.com)
- **CloudBeaver**: https://cb.localhost (or https://cb.yourdomain.com)
- **Tinybird**: https://tb.localhost (or https://tb.yourdomain.com)
- **Health Check**: https://localhost:8080/health

## ⚙️ Configuration

### Environment Management

The infrastructure uses a centralized environment management system:

#### **Centralized Loading (`scripts/env.sh`)**
- **🔧 Single Source**: All environment variables loaded from one file
- **🔄 Smart Loading**: Prevents circular dependencies between scripts
- **📤 Auto Export**: Variables automatically exported for child processes
- **🛡️ Multi-line Support**: Handles complex variables like SSL certificates
- **🎯 Consistent Access**: All scripts use the same environment source

#### **Environment File Structure**
```bash
# .env file contains all configuration
EMAIL=your-email@domain.com
DOMAIN=yourdomain.com
DEPLOYMENT_ENV=local  # or 'production'

# Database passwords
MYSQL_ROOT_PASSWORD=your_secure_password
POSTGRES_PASSWORD=your_secure_password
REDIS_PASSWORD=your_secure_password

# SSL configuration
SSL_COUNTRY=US
SSL_STATE=California
SSL_CITY=San Francisco

# Multi-line variables (SSL certificates)
FLEET_MDM_WINDOWS_WSTEP_IDENTITY_CERT_BYTES="-----BEGIN CERTIFICATE-----
MIIF...your certificate...
-----END CERTIFICATE-----"
```

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
# Choose option 10: Setup localhost infrastructure

# Start services
docker compose up -d

# Check status
docker compose ps
```

### Production Deployment

```bash
# Setup production environment
./infra.sh
# Choose option 11: Setup production infrastructure

# Deploy with your domain
./infra.sh
# Enter your domain and email when prompted

# Start services
docker compose up -d
```

### Individual Service Deployment

Deploy specific services with environment selection:

```bash
# Deploy specific service
./infra.sh
# Choose option 12: Deploy individual service
# Choose environment:
# 1) 🏠 Localhost
# 2) 🌐 Production
# Choose service to deploy:
# 1) 🗄️ CloudBeaver (Database Management)
# 2) 🚀 Fleet (Device Management)
# 3) 📊 Tinybird (Analytics)
# 4) 🐘 MySQL (Database)
# 5) 🐘 PostgreSQL (Database)
# 6) 🔴 Redis (Cache)
# 7) 🌐 Caddy (Reverse Proxy & SSL)
```

**Features:**
- **🎯 Service Selection**: Deploy only the services you need
- **🌍 Environment Support**: Choose between localhost and production
- **🔧 Individual Management**: Start, stop, or restart specific services
- **⚡ Quick Deployment**: Deploy services without full infrastructure setup

## 🛠️ Management

### Infrastructure CLI

The `infra.sh` script provides a comprehensive management interface:

```bash
./infra.sh
```

## Available Options

### 🐳 Docker Management
- **1)** 🐳 Install Docker
- **2)** 👤 Add Docker User
- **3)** 🔍 Check Docker User
- **4)** 🔍 Check Docker
- **5)** 📋 List Docker Services
- **6)** 🧹 Clean Everything (Volumes, Images, Containers, Networks)

### ☁️ Cloud & Backup
- **7)** ☁️ Install AWS CLI
- **8)** 🔐 Verify AWS Credentials
- **9)** 📁 List S3 Backup Files

### 📦 Service Management
- **10)** 🏠 Setup Localhost
- **11)** 🌐 Setup Production (Let's Encrypt)
- **12)** 🎯 Deploy Individual Service
- **13)** ▶️ Start All Services
- **14)** 🛑 Stop All Services
- **15)** 🔄 Restart All Services
- **16)** 📊 Check Service Status
- **17)** 📋 View Service Logs

### 🔧 System Management
- **18)** 📊 System Overview
- **19)** 💾 Memory Usage
- **20)** 🖥️ CPU Usage
- **21)** 💿 Disk Usage

### 🗄️ Backup & Restore
- **22)** 📊 Backup All Databases
- **23)** 🐘 Backup MySQL Only
- **24)** 🐘 Backup PostgreSQL Only
- **25)** 🔴 Backup Redis Only
- **26)** 📊 Backup ClickHouse Only
- **27)** 🔄 Restore Database
- **28)** 📋 List Available Backups
- **29)** ⏰ Setup Automated Backups (Cron) - **Enhanced with Database Selection**
- **30)** 🧪 Test Backup System
- **31)** 📊 Backup Status & Info
- **32)** 🧹 Cleanup Old Backups
- **33)** 🗑️ Remove Automated Backups
- **34)** ⏰ Setup Cleanup Cron (Local & S3)

### 🔐 SSL & Security
- **35)** 🔧 Setup mkcert SSL
- **36)** 🔍 Check SSL Certificates
- **37)** 🔥 Firewall Status

### ⏰ Cron Management
- **38)** 📋 List All Cron Jobs
- **39)** 💾 Save Cron Jobs to File
- **40)** 📥 Restore Cron Jobs from File
- **41)** 🗑️ Remove All Cron Jobs
- **42)** 🧹 Remove Backup Cron Jobs Only
- **43)** 🔧 Edit Cron Jobs Manually
- **44)** 📄 View Cron Logs
- **45)** 🗑️ Remove Cron Logs
- **46)** 🧹 Clean Old Cron Logs

### 🗄️ Database & User Management
- **47)** 🗄️ Database Management Menu
- **48)** 📋 List All Databases
- **49)** ➕ Create Database
- **50)** 🔄 Rename Database
- **51)** 🗑️ Delete Database
- **52)** 👥 List All Users
- **53)** ➕ Add User
- **54)** 🔑 Update User Password
- **55)** 🗑️ Delete User

### ❓ Help & Exit
- **56)** ❓ Help
- **57)** 🚪 Exit

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

### Docker Network & Volume Management

The infrastructure uses optimized Docker networking and volume management:

#### **Absolute Naming**
- **📁 Named Volumes**: All volumes use absolute names (e.g., `caddy_data`, `mysql_data`)
- **🌐 Named Networks**: Networks use absolute names (e.g., `azodik`)
- **🔗 External Networks**: Networks marked as `external: true` to prevent conflicts
- **⚡ No Prefixing**: Docker doesn't add directory prefixes to volume/network names

#### **Volume Structure**
```yaml
volumes:
  caddy_data:
    name: caddy_data
  mysql_data:
    name: mysql_data
  postgres_data:
    name: postgres_data
  redis_data:
    name: redis_data

networks:
  azodik:
    name: azodik
    external: true
```

#### **Benefits**
- **🔧 Easy Management**: Clear, predictable volume and network names
- **🔄 Portability**: Volumes work across different Docker contexts
- **🛡️ Conflict Prevention**: External networks prevent creation conflicts
- **📊 Better Monitoring**: Clear naming for monitoring and debugging

### Backup & Restore

```bash
# Create backup
./infra.sh
# Choose option 22: Backup All Databases

# Restore from backup
./infra.sh
# Choose option 27: Restore Database

# Test backup system
./infra.sh
# Choose option 30: Test Backup System

# Setup automated backups
./infra.sh
# Choose option 29: Setup Automated Backups (Cron)
```

### Enhanced Automated Backup System

The automated backup system now includes advanced database selection and management features:

```bash
# Setup automated backups with database selection
./infra.sh
# Choose option 29: Setup Automated Backups (Cron)
# Choose databases to backup:
# 1) 🐘 MySQL only
# 2) 🐘 PostgreSQL only  
# 3) 🔴 Redis only
# 4) 📊 ClickHouse only
# 5) 🐘 MySQL + PostgreSQL
# 6) 🐘 MySQL + PostgreSQL + Redis
# 7) 🐘 MySQL + PostgreSQL + Redis + ClickHouse (All)
# 8) Custom selection
```

**Key Features:**
- **🎯 Database Selection**: Choose exactly which databases to backup
- **⚡ Performance Optimized**: Skip ClickHouse for faster backups
- **📁 Automatic File Saving**: Cron jobs saved to `cron/` directory
- **📝 Enhanced Descriptions**: Clear descriptions showing selected databases
- **🔄 Custom Combinations**: Mix and match any database combination
- **⏰ Flexible Scheduling**: Daily, twice daily, weekly, or custom schedules

### Enhanced Backup Features

- **🔄 Automatic S3 Upload**: Backups automatically uploaded to S3 when enabled
- **☁️ AWS CLI Auto-Install**: Automatically installs AWS CLI if missing
- **📅 Organized Storage**: Backups organized by date in S3
- **🧹 Automatic Cleanup**: Old backups cleaned up automatically
- **🔍 Backup Testing**: Built-in backup system testing
- **📊 Backup Statistics**: Detailed backup status and information
- **🎯 Database Selection**: Choose which databases to backup (exclude ClickHouse for faster backups)
- **📁 Automatic File Saving**: Cron jobs automatically saved to filesystem
- **📝 Enhanced Descriptions**: Detailed cron job descriptions showing selected databases

### Cloud & Backup Management

The infrastructure includes comprehensive cloud backup management tools:

```bash
# Verify AWS credentials are working
./infra.sh
# Choose option 8: Verify AWS Credentials

# List all backup files in S3
./infra.sh
# Choose option 9: List S3 Backup Files
```

**Features:**
- **🔐 Credential Verification**: Test AWS credentials using `aws sts get-caller-identity`
- **📁 S3 File Browser**: List all backup files and folders in your S3 bucket
- **☁️ Environment-based**: Uses credentials from `.env` file, not local AWS config
- **🔍 Detailed Information**: Shows file sizes, dates, and folder structure
- **🌐 Multi-endpoint Support**: Works with AWS S3 and custom S3-compatible endpoints

### Database & User Management

The infrastructure includes comprehensive database and user management tools for MySQL and PostgreSQL:

```bash
# Access database management menu
./infra.sh
# Choose option 47: Database Management Menu

# Or run specific operations directly
./infra.sh
# Choose option 48: List All Databases
# Choose option 49: Create Database
# Choose option 52: List All Users
# Choose option 53: Add User
# etc.
```

**Database Operations:**
- **📋 List All Databases**: View all databases in MySQL or PostgreSQL
- **➕ Create Database**: Create new databases with proper permissions
- **🔄 Rename Database**: Safely rename existing databases
- **🗑️ Delete Database**: Remove databases with confirmation prompts

**User Operations:**
- **👥 List All Users**: View all database users and their permissions
- **➕ Add User**: Create new database users with passwords
- **🔑 Update User Password**: Change user passwords securely
- **🗑️ Delete User**: Remove users with confirmation prompts

**Features:**
- **🔒 Security**: Hidden password prompts and confirmation for destructive operations
- **🛡️ Validation**: Checks if database services are running before operations
- **📊 User-friendly**: Clear prompts and detailed error messages
- **🔄 Cross-platform**: Works on both macOS and Linux systems
- **🎯 Database Support**: Full support for MySQL and PostgreSQL

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
# Choose option 36: Check SSL Certificates

# Setup mkcert for localhost
./infra.sh
# Choose option 35: Setup mkcert SSL
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

# Test AWS credentials using CLI
./infra.sh
# Choose option 8: Verify AWS Credentials

# List S3 backup files using CLI
./infra.sh
# Choose option 9: List S3 Backup Files
```

#### 6. Platform Compatibility Issues
```bash
# Check system architecture
uname -m

# Check Docker platform support
docker info | grep -E "(Architecture|Platform)"

# Test platform detection
source scripts/core.sh && detect_platform

# Rebuild CloudBeaver with correct platform
docker compose up -d --force-recreate cloudbeaver
```

#### 7. Environment Variable Issues
```bash
# Check if env.sh is loading correctly
source scripts/env.sh && echo "Environment loaded successfully"

# Test specific variables
source scripts/env.sh && echo "DOMAIN: $DOMAIN"
source scripts/env.sh && echo "MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_PASSWORD"

# Check for circular dependencies
source scripts/env.sh && echo "ENV_LOADED: $ENV_LOADED"
```

#### 8. Cron Job Issues
```bash
# Check if cron jobs are saved to files
ls -la cron/

# View saved cron job files
cat cron/crontab_*.txt

# Check cron job descriptions
./infra.sh
# Choose option 38: List All Cron Jobs

# Test cron job execution
source scripts/backup.sh && backup_mysql_only
```

#### 9. Docker Network Issues
```bash
# Check for network conflicts
docker network ls | grep azodik

# Remove conflicting networks
docker network rm azodik

# Recreate network
docker network create azodik

# Check volume names
docker volume ls | grep -E "(caddy_data|mysql_data|postgres_data|redis_data)"
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
│   ├── 🗄️ database.sh          # Database & user management
│   ├── 🚀 setup.sh             # Setup functions
│   └── 🔧 env.sh               # Centralized environment loader
├── 📁 ssl/                     # SSL certificates
│   ├── 📁 mkcert/              # Localhost certificates
│   ├── 📁 localhost-ca/        # Localhost CA
│   ├── 📁 mysql/               # MySQL SSL certificates
│   ├── 📁 postgres/            # PostgreSQL SSL certificates
│   └── 📁 redis/               # Redis SSL certificates
├── 📁 cron/                    # Cron job backups
│   └── 📄 crontab_*.txt        # Saved cron job files
├── 📁 backups/                 # Database backups
│   ├── 📁 YYYY-MM-DD/          # Date-organized backups
│   │   ├── 📄 mysql_backup_YYYYMMDD_HHMMSS.sql.gz
│   │   ├── 📄 postgres_backup_YYYYMMDD_HHMMSS.sql.gz
│   │   ├── 📄 redis_backup_YYYYMMDD_HHMMSS.rdb.gz
│   │   └── 📄 clickhouse_backup_YYYYMMDD_HHMMSS.sql.gz
│   ├── 📄 dump.sql             # Legacy database dumps
│   └── 📄 backup-restore.sql   # Restore scripts
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

