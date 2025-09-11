#!/bin/bash

# 🧠 Core Functions
# Essential utilities and infrastructure management functions
# Consolidated from 12+ function files into one optimized module

# Load environment variables with multi-line support
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    # Source simple vars directly
    set -a
    source "$SCRIPT_DIR/.env"
    set +a

    # Convert multi-line WSTEP variables and add proper indentation for YAML
    if [ -n "${FLEET_MDM_WINDOWS_WSTEP_IDENTITY_CERT_BYTES:-}" ]; then
        FLEET_MDM_WINDOWS_WSTEP_IDENTITY_CERT_BYTES=$(printf '%s\n' "${FLEET_MDM_WINDOWS_WSTEP_IDENTITY_CERT_BYTES}" | sed 's/\\n/\n/g' | sed '/^[[:space:]]*$/d' | sed '1!s/^/        /')
    fi
    if [ -n "${FLEET_MDM_WINDOWS_WSTEP_IDENTITY_KEY_BYTES:-}" ]; then
        FLEET_MDM_WINDOWS_WSTEP_IDENTITY_KEY_BYTES=$(printf '%s\n' "${FLEET_MDM_WINDOWS_WSTEP_IDENTITY_KEY_BYTES}" | sed 's/\\n/\n/g' | sed '/^[[:space:]]*$/d' | sed '1!s/^/        /')
    fi
fi

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if user has sudo privileges
has_sudo_privileges() {
    sudo -n true 2>/dev/null
}

# Run command with sudo if needed
run_with_sudo() {
    local cmd="$1"
    local description="${2:-Running command}"
    
    echo "🔐 $description..."
    if has_sudo_privileges; then
        sudo $cmd
    else
        echo "Please enter your password when prompted:"
        sudo $cmd
    fi
}

# Get current timestamp
get_timestamp() {
    date '+%Y%m%d_%H%M%S'
}

# Get display timestamp
get_display_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Create logs directory
ensure_logs_directory() {
    local logs_dir="logs"
    if [ ! -d "$logs_dir" ]; then
        mkdir -p "$logs_dir"
    fi
    echo "$logs_dir"
}

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

# Log message with timestamp
log_message() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(get_display_timestamp)
    local logs_dir=$(ensure_logs_directory)
    local log_file="$logs_dir/infrastructure_$(date '+%Y%m%d').log"
    
    local formatted_message="[$timestamp] [$level] $message"
    echo "$formatted_message"
    echo "$formatted_message" >> "$log_file"
}

# Log functions
log_error() { log_message "$1" "ERROR"; }
log_warning() { log_message "$1" "WARN"; }
log_info() { log_message "$1" "INFO"; }
log_success() { log_message "$1" "SUCCESS"; }

# =============================================================================
# DOCKER FUNCTIONS
# =============================================================================

# Install Docker
install_docker() {
    echo "🐳 Installing Docker..."
    echo "======================"
    echo ""
    
    if command -v docker >/dev/null 2>&1; then
        echo "✅ Docker is already installed"
        docker --version
        return 0
    fi
    
    echo "📦 Installing Docker..."
    if command -v apt-get >/dev/null 2>&1; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm -f get-docker.sh
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    elif command -v brew >/dev/null 2>&1; then
        brew install --cask docker
    else
        echo "❌ Unsupported operating system"
        return 0
    fi
    
    echo "✅ Docker installed successfully"
    docker --version
}

# Install AWS CLI
install_aws_cli() {
    echo "☁️ Installing AWS CLI..."
    echo "======================="
    echo ""
    
    if command -v aws >/dev/null 2>&1; then
        echo "✅ AWS CLI is already installed"
        aws --version
        return 0
    fi
    
    echo "📦 Installing AWS CLI..."
    if command -v apt-get >/dev/null 2>&1; then
        # Ubuntu/Debian
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
    elif command -v yum >/dev/null 2>&1; then
        # CentOS/RHEL
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
    elif command -v brew >/dev/null 2>&1; then
        # macOS
        brew install awscli
    elif command -v pip3 >/dev/null 2>&1; then
        # Fallback to pip
        pip3 install awscli --upgrade --user
        echo "⚠️  AWS CLI installed via pip. You may need to add ~/.local/bin to your PATH"
    else
        echo "❌ Unsupported operating system or package manager"
        echo "💡 Please install AWS CLI manually: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        return 1
    fi
    
    echo "✅ AWS CLI installed successfully"
    aws --version
    
    echo ""
    echo "🔧 Next steps:"
    echo "1. Configure AWS credentials: aws configure"
    echo "2. Or set environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY"
    echo "3. Test connection: aws sts get-caller-identity"
}

# Get Docker Compose command
get_docker_compose_cmd() {
    if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        echo "docker compose"
    elif command -v docker-compose >/dev/null 2>&1; then
        echo "docker-compose"
    else
        echo "docker compose"
    fi
}

# Add Docker user
add_docker_user() {
    echo "👤 Adding Docker User"
    echo "===================="
    echo ""
    
    DOCKER_USER=${DOCKER_USER:-"dockeruser"}
    USER_PASSWORD=${USER_PASSWORD:-""}
    
    # Check if user already exists
    if id "$DOCKER_USER" >/dev/null 2>&1; then
        echo "✅ User $DOCKER_USER already exists"
        return 0
    fi
    
    # Create user
    echo "📝 Creating user: $DOCKER_USER"
    sudo useradd -m -s /bin/bash "$DOCKER_USER"
    
    # Set password if provided
    if [ -n "$USER_PASSWORD" ]; then
        echo "$DOCKER_USER:$USER_PASSWORD" | sudo chpasswd
        echo "✅ Password set for $DOCKER_USER"
    else
        echo "⚠️  No password set for $DOCKER_USER"
    fi
    
    # Add to docker group
    echo "🔧 Adding $DOCKER_USER to docker group..."
    sudo usermod -aG docker "$DOCKER_USER"
    
    # Add to sudoers for Docker commands
    echo "🔐 Adding Docker privileges..."
    echo "$DOCKER_USER ALL=(ALL) NOPASSWD: /usr/bin/docker, /usr/bin/docker-compose, /usr/local/bin/docker-compose" | sudo tee /etc/sudoers.d/docker-$DOCKER_USER
    
    echo "✅ Docker user $DOCKER_USER created successfully"
    echo ""
    echo "🔧 Next steps:"
    echo "1. Logout and login as $DOCKER_USER"
    echo "2. Test Docker access: docker --version"
    echo "3. Test Docker Compose: docker compose version"
}

# Check Docker user
check_docker_user() {
    echo "🔍 Check Docker User"
    echo "==================="
    echo ""
    
    DOCKER_USER=${DOCKER_USER:-"dockeruser"}
    
    if id "$DOCKER_USER" >/dev/null 2>&1; then
        echo "✅ User $DOCKER_USER exists"
        echo "   UID: $(id -u "$DOCKER_USER")"
        echo "   GID: $(id -g "$DOCKER_USER")"
        echo "   Groups: $(groups "$DOCKER_USER")"
        
        # Check if in docker group
        if groups "$DOCKER_USER" | grep -q docker; then
            echo "✅ User is in docker group"
        else
            echo "❌ User is NOT in docker group"
        fi
        
        # Check sudoers
        if sudo -l -U "$DOCKER_USER" 2>/dev/null | grep -q docker; then
            echo "✅ User has Docker sudo privileges"
        else
            echo "❌ User does NOT have Docker sudo privileges"
        fi
    else
        echo "❌ User $DOCKER_USER does not exist"
        echo "💡 Run 'Add Docker User' option to create it"
    fi
}

# Check Docker installation
check_docker() {
    echo "🔍 Check Docker"
    echo "=============="
    echo ""
    
    # Check Docker installation
    if command -v docker >/dev/null 2>&1; then
        echo "✅ Docker is installed"
        echo "   Version: $(docker --version)"
        echo "   Location: $(which docker)"
    else
        echo "❌ Docker is not installed"
        return 0
    fi
    
    # Check Docker Compose
    if command -v docker-compose >/dev/null 2>&1; then
        echo "✅ Docker Compose is installed"
        echo "   Version: $(docker-compose --version)"
        echo "   Location: $(which docker-compose)"
    elif docker compose version >/dev/null 2>&1; then
        echo "✅ Docker Compose (plugin) is available"
        echo "   Version: $(docker compose version)"
    else
        echo "❌ Docker Compose is not available"
    fi
    
    # Check Docker daemon
    if docker info >/dev/null 2>&1; then
        echo "✅ Docker daemon is running"
        echo "   Containers: $(docker ps -q | wc -l) running"
        echo "   Images: $(docker images -q | wc -l) available"
    else
        echo "❌ Docker daemon is not running"
        echo "💡 Start Docker daemon: sudo systemctl start docker"
    fi
    
    # Check Docker group
    if getent group docker >/dev/null 2>&1; then
        echo "✅ Docker group exists"
        echo "   Members: $(getent group docker | cut -d: -f4)"
    else
        echo "❌ Docker group does not exist"
    fi
}

# Clean everything Docker (volumes, images, containers, networks)
clean_docker_everything() {
    echo "🧹 Clean Everything Docker"
    echo "=========================="
    echo ""
    
    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ Docker is not installed"
        return 0
    fi
    
    echo "⚠️  WARNING: This will remove ALL Docker data!"
    echo "This includes:"
    echo "  🐳 All containers (running and stopped)"
    echo "  🖼️  All images"
    echo "  📦 All volumes"
    echo "  🌐 All networks (except default)"
    echo "  🧹 All build cache"
    echo ""
    echo "⚠️  This action CANNOT be undone!"
    echo ""
    
    read -p "Are you absolutely sure you want to continue? (yes/NO): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "❌ Operation cancelled"
        return 0
    fi
    
    echo ""
    echo "🛑 Stopping all containers..."
    docker stop $(docker ps -aq) 2>/dev/null || true
    
    echo "🗑️  Removing all containers..."
    docker rm $(docker ps -aq) 2>/dev/null || true
    
    echo "🗑️  Removing all images..."
    docker rmi $(docker images -aq) 2>/dev/null || true
    
    echo "🗑️  Removing all volumes..."
    docker volume rm $(docker volume ls -q) 2>/dev/null || true
    
    echo "🗑️  Removing all networks (except default)..."
    docker network rm $(docker network ls -q --filter type=custom) 2>/dev/null || true
    
    echo "🧹 Cleaning build cache..."
    docker builder prune -af 2>/dev/null || true
    
    echo "🧹 Cleaning system..."
    docker system prune -af --volumes 2>/dev/null || true
    
    echo ""
    echo "✅ Docker cleanup completed!"
    echo ""
    echo "📊 Remaining Docker resources:"
    echo "  🐳 Containers: $(docker ps -aq | wc -l)"
    echo "  🖼️  Images: $(docker images -q | wc -l)"
    echo "  📦 Volumes: $(docker volume ls -q | wc -l)"
    echo "  🌐 Networks: $(docker network ls -q | wc -l)"
}

# Generate SSL certificates for all services
generate_service_ssl_certificates() {
    echo "🔐 Generating SSL Certificates for All Services"
    echo "=============================================="
    echo ""
    
    # Create SSL directories for each service
    mkdir -p ssl/mysql ssl/postgres ssl/redis ssl/fleet
    
    # Generate CA certificate
    log_info "Generating CA certificate..."
    openssl genrsa -out ssl/ca-key.pem 4096
    openssl req -new -x509 -days 365 -key ssl/ca-key.pem -out ssl/ca-cert.pem -subj "/C=${SSL_COUNTRY:-US}/ST=${SSL_STATE:-CA}/L=${SSL_CITY:-San Francisco}/O=${SSL_ORG:-YourCompany}/OU=${SSL_OU:-IT}/CN=${SSL_CN:-YourCompany CA}"
    
    # Copy CA certificate to all service directories
    local ssl_prefix="${SSL_PREFIX:-my-company}"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # On Linux, use sudo to copy files to directories owned by container users
        sudo cp ssl/ca-cert.pem ssl/mysql/${ssl_prefix}-ca.crt
        sudo cp ssl/ca-cert.pem ssl/postgres/${ssl_prefix}-ca.crt
        sudo cp ssl/ca-cert.pem ssl/redis/${ssl_prefix}-ca.crt
        sudo cp ssl/ca-cert.pem ssl/fleet/${ssl_prefix}-ca.crt
    else
        # On macOS/Windows, regular copy should work
        cp ssl/ca-cert.pem ssl/mysql/${ssl_prefix}-ca.crt
        cp ssl/ca-cert.pem ssl/postgres/${ssl_prefix}-ca.crt
        cp ssl/ca-cert.pem ssl/redis/${ssl_prefix}-ca.crt
        cp ssl/ca-cert.pem ssl/fleet/${ssl_prefix}-ca.crt
    fi
    
    # Generate MySQL SSL certificates
    log_info "Generating MySQL SSL certificates..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo openssl genrsa -out ssl/mysql/${ssl_prefix}-mysql.key 4096
        sudo openssl req -new -key ssl/mysql/${ssl_prefix}-mysql.key -out ssl/mysql/${ssl_prefix}-mysql.csr -subj "/C=${SSL_COUNTRY:-US}/ST=${SSL_STATE:-CA}/L=${SSL_CITY:-San Francisco}/O=${SSL_ORG:-YourCompany}/OU=${SSL_OU:-IT}/CN=mysql"
        sudo openssl x509 -req -in ssl/mysql/${ssl_prefix}-mysql.csr -CA ssl/ca-cert.pem -CAkey ssl/ca-key.pem -out ssl/mysql/${ssl_prefix}-mysql.crt -days 365 -CAcreateserial
        sudo rm ssl/mysql/${ssl_prefix}-mysql.csr
    else
        openssl genrsa -out ssl/mysql/${ssl_prefix}-mysql.key 4096
        openssl req -new -key ssl/mysql/${ssl_prefix}-mysql.key -out ssl/mysql/${ssl_prefix}-mysql.csr -subj "/C=${SSL_COUNTRY:-US}/ST=${SSL_STATE:-CA}/L=${SSL_CITY:-San Francisco}/O=${SSL_ORG:-YourCompany}/OU=${SSL_OU:-IT}/CN=mysql"
        openssl x509 -req -in ssl/mysql/${ssl_prefix}-mysql.csr -CA ssl/ca-cert.pem -CAkey ssl/ca-key.pem -out ssl/mysql/${ssl_prefix}-mysql.crt -days 365 -CAcreateserial
        rm ssl/mysql/${ssl_prefix}-mysql.csr
    fi
    
    # Generate PostgreSQL SSL certificates
    log_info "Generating PostgreSQL SSL certificates..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo openssl genrsa -out ssl/postgres/${ssl_prefix}-postgres.key 4096
        sudo openssl req -new -key ssl/postgres/${ssl_prefix}-postgres.key -out ssl/postgres/${ssl_prefix}-postgres.csr -subj "/C=${SSL_COUNTRY:-US}/ST=${SSL_STATE:-CA}/L=${SSL_CITY:-San Francisco}/O=${SSL_ORG:-YourCompany}/OU=${SSL_OU:-IT}/CN=postgres"
        sudo openssl x509 -req -in ssl/postgres/${ssl_prefix}-postgres.csr -CA ssl/ca-cert.pem -CAkey ssl/ca-key.pem -out ssl/postgres/${ssl_prefix}-postgres.crt -days 365 -CAcreateserial
        sudo rm ssl/postgres/${ssl_prefix}-postgres.csr
    else
        openssl genrsa -out ssl/postgres/${ssl_prefix}-postgres.key 4096
        openssl req -new -key ssl/postgres/${ssl_prefix}-postgres.key -out ssl/postgres/${ssl_prefix}-postgres.csr -subj "/C=${SSL_COUNTRY:-US}/ST=${SSL_STATE:-CA}/L=${SSL_CITY:-San Francisco}/O=${SSL_ORG:-YourCompany}/OU=${SSL_OU:-IT}/CN=postgres"
        openssl x509 -req -in ssl/postgres/${ssl_prefix}-postgres.csr -CA ssl/ca-cert.pem -CAkey ssl/ca-key.pem -out ssl/postgres/${ssl_prefix}-postgres.crt -days 365 -CAcreateserial
        rm ssl/postgres/${ssl_prefix}-postgres.csr
    fi
    
    # Generate Redis SSL certificates
    log_info "Generating Redis SSL certificates..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo openssl genrsa -out ssl/redis/${ssl_prefix}-redis.key 4096
        sudo openssl req -new -key ssl/redis/${ssl_prefix}-redis.key -out ssl/redis/${ssl_prefix}-redis.csr -subj "/C=${SSL_COUNTRY:-US}/ST=${SSL_STATE:-CA}/L=${SSL_CITY:-San Francisco}/O=${SSL_ORG:-YourCompany}/OU=${SSL_OU:-IT}/CN=redis"
        sudo openssl x509 -req -in ssl/redis/${ssl_prefix}-redis.csr -CA ssl/ca-cert.pem -CAkey ssl/ca-key.pem -out ssl/redis/${ssl_prefix}-redis.crt -days 365 -CAcreateserial
        sudo rm ssl/redis/${ssl_prefix}-redis.csr
    else
        openssl genrsa -out ssl/redis/${ssl_prefix}-redis.key 4096
        openssl req -new -key ssl/redis/${ssl_prefix}-redis.key -out ssl/redis/${ssl_prefix}-redis.csr -subj "/C=${SSL_COUNTRY:-US}/ST=${SSL_STATE:-CA}/L=${SSL_CITY:-San Francisco}/O=${SSL_ORG:-YourCompany}/OU=${SSL_OU:-IT}/CN=redis"
        openssl x509 -req -in ssl/redis/${ssl_prefix}-redis.csr -CA ssl/ca-cert.pem -CAkey ssl/ca-key.pem -out ssl/redis/${ssl_prefix}-redis.crt -days 365 -CAcreateserial
        rm ssl/redis/${ssl_prefix}-redis.csr
    fi
    
    # Generate Fleet SSL certificates
    log_info "Generating Fleet SSL certificates..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo openssl genrsa -out ssl/fleet/${ssl_prefix}-fleet.key 4096
        sudo openssl req -new -key ssl/fleet/${ssl_prefix}-fleet.key -out ssl/fleet/${ssl_prefix}-fleet.csr -subj "/C=${SSL_COUNTRY:-US}/ST=${SSL_STATE:-CA}/L=${SSL_CITY:-San Francisco}/O=${SSL_ORG:-YourCompany}/OU=${SSL_OU:-IT}/CN=fleet"
        sudo openssl x509 -req -in ssl/fleet/${ssl_prefix}-fleet.csr -CA ssl/ca-cert.pem -CAkey ssl/ca-key.pem -out ssl/fleet/${ssl_prefix}-fleet.crt -days 365 -CAcreateserial
        sudo rm ssl/fleet/${ssl_prefix}-fleet.csr
    else
        openssl genrsa -out ssl/fleet/${ssl_prefix}-fleet.key 4096
        openssl req -new -key ssl/fleet/${ssl_prefix}-fleet.key -out ssl/fleet/${ssl_prefix}-fleet.csr -subj "/C=${SSL_COUNTRY:-US}/ST=${SSL_STATE:-CA}/L=${SSL_CITY:-San Francisco}/O=${SSL_ORG:-YourCompany}/OU=${SSL_OU:-IT}/CN=fleet"
        openssl x509 -req -in ssl/fleet/${ssl_prefix}-fleet.csr -CA ssl/ca-cert.pem -CAkey ssl/ca-key.pem -out ssl/fleet/${ssl_prefix}-fleet.crt -days 365 -CAcreateserial
        rm ssl/fleet/${ssl_prefix}-fleet.csr
    fi
    
    # Set proper permissions
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo chmod 600 ssl/*/*.key
        sudo chmod 644 ssl/*/*.crt
    else
        chmod 600 ssl/*/*.key
        chmod 644 ssl/*/*.crt
    fi
   
   # Set correct ownership for database services (Linux only)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo chown -R 999:999 ssl/mysql/  ssl/postgres/ ssl/redis/
        sudo chmod 755 ssl/mysql/ ssl/postgres/ ssl/redis/
        sudo chmod 600 ssl/mysql/*.key
        sudo chmod 600 ssl/postgres/*.key
        sudo chmod 600 ssl/redis/*.key
        sudo chmod 644 ssl/postgres/*.crt
        sudo chmod 644 ssl/mysql/*.crt
        sudo chmod 644 ssl/redis/*.crt
        
        # Set ownership for fleet
        sudo chown -R 999:999 ssl/fleet/
        sudo chmod 755 ssl/fleet/
        
        log_info "Set correct ownership for Linux container users"
    else
        log_info "Skipping ownership changes on non-Linux system: $OSTYPE"
    fi
    
    log_success "SSL certificates generated for all services!"
    echo ""
    echo "📁 Generated certificates:"
    echo "  🐘 MySQL: ssl/mysql/${ssl_prefix}-*.crt"
    echo "  🐘 PostgreSQL: ssl/postgres/${ssl_prefix}-*.crt"
    echo "  🔴 Redis: ssl/redis/${ssl_prefix}-*.crt"
    echo "  🚀 Fleet: ssl/fleet/${ssl_prefix}-*.crt"
    echo "  🔐 CA: ssl/ca-cert.pem"
}

# =============================================================================
# SYSTEM MONITORING FUNCTIONS
# =============================================================================

# Show system overview
show_system_overview() {
    echo "📊 System Overview"
    echo "=================="
    echo ""
    
    # OS Information
    echo "🖥️  Operating System:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "   macOS $(sw_vers -productVersion)"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2
    fi
    echo ""
    
    # Memory Usage
    echo "💾 Memory Usage:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        vm_stat | grep -E "(Pages free|Pages active|Pages inactive|Pages wired down)"
    else
        free -h
    fi
    echo ""
    
    # CPU Usage
    echo "🖥️  CPU Usage:"
    if command_exists top; then
        top -l 1 | grep "CPU usage" 2>/dev/null || top -bn1 | grep "Cpu(s)" 2>/dev/null || echo "   CPU usage information not available"
    fi
    echo ""
    
    # Disk Usage
    echo "💿 Disk Usage:"
    df -h | grep -E "(Filesystem|/dev/)"
    echo ""
    
    # Docker Status
    echo "🐳 Docker Status:"
    if command_exists docker; then
        echo "   Docker: $(docker --version)"
        echo "   Containers: $(docker ps -q | wc -l) running"
        echo "   Images: $(docker images -q | wc -l) available"
    else
        echo "   Docker: Not installed"
    fi
    echo ""
}

# Show memory usage
show_memory_usage() {
    echo "💾 Memory Usage"
    echo "=============="
    echo ""
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "📊 Memory Information:"
        vm_stat | grep -E "(Pages free|Pages active|Pages inactive|Pages speculative|Pages wired down|Pages compressed)"
        echo ""
        
        echo "📈 Memory Usage (MB):"
        free_mb=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
        active_mb=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
        inactive_mb=$(vm_stat | grep "Pages inactive" | awk '{print $3}' | sed 's/\.//')
        wired_mb=$(vm_stat | grep "Pages wired down" | awk '{print $4}' | sed 's/\.//')
        
        # Convert pages to MB (1 page = 4KB on macOS)
        free_mb=$((free_mb * 4 / 1024))
        active_mb=$((active_mb * 4 / 1024))
        inactive_mb=$((inactive_mb * 4 / 1024))
        wired_mb=$((wired_mb * 4 / 1024))
        
        echo "Free: ${free_mb}MB"
        echo "Active: ${active_mb}MB"
        echo "Inactive: ${inactive_mb}MB"
        echo "Wired: ${wired_mb}MB"
    else
        echo "📊 Memory Information:"
        free -h
        echo ""
        
        echo "📈 Detailed Memory Info:"
        cat /proc/meminfo | grep -E "(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree)"
    fi
}

# Show CPU usage
show_cpu_usage() {
    echo "🖥️  CPU Usage"
    echo "============"
    echo ""
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "📊 CPU Information:"
        sysctl -n machdep.cpu.brand_string
        echo "Cores: $(sysctl -n hw.ncpu)"
        echo ""
        
        echo "📈 Current CPU Usage:"
        top -l 1 | grep "CPU usage"
    else
        echo "📊 CPU Information:"
        lscpu | grep -E "(Model name|CPU\(s\)|Thread|Core|Socket)"
        echo ""
        
        echo "📈 Current CPU Usage:"
        top -bn1 | grep "Cpu(s)"
    fi
}

# Show disk usage
show_disk_usage() {
    echo "💿 Disk Usage"
    echo "============="
    echo ""
    
    echo "📊 Disk Space:"
    df -h
    echo ""
    
    echo "📈 Directory Sizes (Top 10):"
    du -h / 2>/dev/null | sort -hr | head -10 || du -h . 2>/dev/null | sort -hr | head -10
}

# =============================================================================
# INFRASTRUCTURE SETUP FUNCTIONS
# =============================================================================

# Detect and set platform
detect_platform() {
    local arch=$(uname -m)
    case "$arch" in
        "x86_64")
            export CLOUDBEAVER_PLATFORM="linux/amd64"
            export TINYBIRD_PLATFORM="linux/amd64"
            export FLEET_PLATFORM="linux/amd64"
            ;;
        "aarch64"|"arm64")
            export CLOUDBEAVER_PLATFORM="linux/arm64"
            export TINYBIRD_PLATFORM="linux/arm64"
            export FLEET_PLATFORM="linux/arm64"
            ;;
        "armv7l")
            export CLOUDBEAVER_PLATFORM="linux/arm/v7"
            export TINYBIRD_PLATFORM="linux/arm/v7"
            export FLEET_PLATFORM="linux/arm/v7"
            ;;
        *)
            export CLOUDBEAVER_PLATFORM="linux/amd64"
            export TINYBIRD_PLATFORM="linux/amd64"
            export FLEET_PLATFORM="linux/amd64"
            log_warning "Unknown architecture: $arch, defaulting to linux/amd64"
            ;;
    esac
    log_info "Detected platform: CLOUDBEAVER_PLATFORM=$CLOUDBEAVER_PLATFORM, TINYBIRD_PLATFORM=$TINYBIRD_PLATFORM, FLEET_PLATFORM=$FLEET_PLATFORM"
}

# Setup infrastructure
setup_infrastructure() {
    local environment="${1:-localhost}"
    local domain="${2:-}"
    local email="${3:-}"
    
    # Detect platform automatically
    detect_platform
    
    log_info "Setting up infrastructure for environment: $environment"
    
    # Show Cloudflare DNS info for production
    if [ "$environment" = "production" ] && [ -n "${CLOUDFLARE_API_TOKEN:-}" ]; then
        log_info "Using Cloudflare DNS for automatic SSL certificate management"
    fi
    
    # 1. Generate Caddyfile
    generate_caddyfile "$environment" "$domain" "$email"
    
    # 2. Generate Docker Compose
    generate_docker_compose "$environment"
    
    # 3. Generate SSL certificates if needed
    if [ "$environment" = "localhost" ]; then
        # For localhost, always ensure mkcert certificates exist
        if [ ! -f "ssl/mkcert/localhost.pem" ] || [ ! -f "ssl/mkcert/localhost-key.pem" ]; then
            log_info "Setting up mkcert SSL certificates for localhost..."
            setup_mkcert_ssl
            # Regenerate Caddyfile with proper SSL certificates
            log_info "Regenerating Caddyfile with mkcert certificates..."
            generate_caddyfile "$environment" "$domain" "$email"
        else
            log_info "mkcert SSL certificates already exist"
        fi
        
        # Generate SSL certificates for all services
        log_info "Generating SSL certificates for all services..."
        generate_service_ssl_certificates
    elif [ "$environment" = "production" ]; then
        # For production, generate SSL certificates for database services
        log_info "Generating SSL certificates for database services..."
        generate_service_ssl_certificates
    elif [ ! -d "ssl" ] || [ -z "$(ls -A ssl 2>/dev/null)" ]; then
        log_info "Generating SSL certificates..."
        if [ -f "scripts/generate-rsa-certificates.sh" ]; then
            ./scripts/generate-rsa-certificates.sh
        else
            log_warning "SSL certificate generation script not found"
        fi
    fi
    
    # 4. Create network
    log_info "Creating Docker network: ${DOCKER_NETWORK:-my-network}"
    docker network create ${DOCKER_NETWORK:-my-network} 2>/dev/null || true
    
    log_success "Infrastructure setup complete!"
    echo ""
    echo "🚀 Next steps:"
    echo "1. Start all services: docker compose up -d"
    echo "2. Check status: docker compose ps"
    echo "3. View logs: docker compose logs -f"
    echo "4. Access services via HTTPS"
}

# Generate Caddyfile
generate_caddyfile() {
    local environment="${1:-localhost}"
    local domain="${2:-}"
    local email="${3:-}"
    
    log_info "Generating Caddyfile for environment: $environment"
    
    case "$environment" in
        "localhost")
            generate_localhost_caddyfile
            ;;
        "production")
            generate_production_caddyfile "$domain" "$email"
            ;;
        "development")
            generate_development_caddyfile
            ;;
        *)
            log_error "Unknown environment: $environment"
            return 0
            ;;
    esac
}

# Generate localhost Caddyfile
generate_localhost_caddyfile() {
    # Check if mkcert certificates exist
    if [ -f "ssl/mkcert/localhost.pem" ] && [ -f "ssl/mkcert/localhost-key.pem" ]; then
        log_info "Using mkcert certificates"
        local tls_config="tls /etc/caddy/ssl/localhost.pem /etc/caddy/ssl/localhost-key.pem"
    else
        log_warning "mkcert certificates not found, using internal certificates"
        log_info "Run './infra.sh' and choose option 18 to setup mkcert SSL"
        local tls_config="tls internal"
    fi
    
    cat > Caddyfile << EOF
# Localhost Configuration
# All services accessible via localhost with valid SSL certificates

# CloudBeaver - Database Management
cb.localhost {
    $tls_config
    reverse_proxy cloudbeaver:8978
    encode zstd gzip
    log {
        output file /data/cloudbeaver_access.log
    }
    header {
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
    }
}

# Fleet - Device Management
fleet.localhost {
    $tls_config
    reverse_proxy fleet:8888
    encode zstd gzip
    log {
        output file /data/fleet_access.log
    }
    header {
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
    }
}

# Tinybird - Analytics
tb.localhost {
    $tls_config
    reverse_proxy tinybird:7181
    encode zstd gzip
    log {
        output file /data/tinybird_access.log
    }
    header {
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
    }
}


# Health Check
localhost:8080 {
    $tls_config
    respond /health "OK" 200
    header Content-Type "text/plain"
    header Cache-Control "no-cache"
    log {
        output file /data/health_access.log
    }
}
EOF
    
    log_success "Localhost Caddyfile generated"
}

# Generate production Caddyfile
generate_production_caddyfile() {

    
    cat > Caddyfile << EOF
# Production Configuration - Let's Encrypt SSL with Cloudflare DNS
# Domain: $DOMAIN
# Email: $EMAIL

# Global email for Let's Encrypt
{
    email $EMAIL
}

# CloudBeaver - Database Management
cb.$DOMAIN {
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }
    reverse_proxy cloudbeaver:8978
    encode zstd gzip
    log {
        output file /data/cloudbeaver_access.log
    }
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
        -Server
    }
}

# Fleet - Device Management
fleet.$DOMAIN {
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }
    reverse_proxy fleet:8888
    encode zstd gzip
    log {
        output file /data/fleet_access.log
    }
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
        -Server
    }
}

# Tinybird - Analytics
tb.$DOMAIN {
    tls {
        dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    }
    reverse_proxy tinybird:7181
    encode zstd gzip
    log {
        output file /data/tinybird_access.log
    }
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "SAMEORIGIN"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
        -Server
    }
}

EOF
    
    log_success "Production Caddyfile generated with Let's Encrypt and Cloudflare DNS!"
}



# Generate Docker Compose
generate_docker_compose() {
    local environment="${1:-localhost}"
    local output_file="docker-compose.yml"
    
    log_info "Generating Docker Compose for environment: $environment"
    
    cat > "$output_file" << EOF
services:
  # Caddy Reverse Proxy with Automatic SSL
  caddy:
    image: caddybuilds/caddy-cloudflare:latest
    container_name: caddy
    cap_add:
      - NET_ADMIN
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
      - ./ssl/mkcert:/etc/caddy/ssl:ro
      - ./ssl/localhost-ca:/etc/caddy/ssl-openssl:ro
    environment:
      CLOUDFLARE_API_TOKEN: \${CLOUDFLARE_API_TOKEN}
    networks:
      - ${DOCKER_NETWORK:-my-network}

  # CloudBeaver - Database Management
  cloudbeaver:
    image: dbeaver/cloudbeaver:latest
    platform: linux/amd64
    container_name: cloudbeaver
    restart: unless-stopped
    environment:
      CB_SERVER_URL: cb.localhost
      CB_SERVER_HTTPS: "false"
    volumes:
      - cloudbeaver_data:/opt/cloudbeaver/workspace
    networks:
      - ${DOCKER_NETWORK:-my-network}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8978/status"]
      interval: 30s
      timeout: 10s
      retries: 3

  # MySQL Database
  mysql:
    image: mysql:8.4.6
    container_name: mysql
    restart: unless-stopped
    ports:
      - "\${MYSQL_PORT:-3306}:3306"   # External:Internal MySQL port
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: \${FLEET_MYSQL_DATABASE}
      MYSQL_USER: \${FLEET_MYSQL_USERNAME}
      MYSQL_PASSWORD: \${FLEET_MYSQL_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
      - ./ssl/mysql:/etc/mysql/ssl:ro
    command: >
      --ssl-ca=/etc/mysql/ssl/\${SSL_PREFIX:-my-company}-ca.crt
      --ssl-cert=/etc/mysql/ssl/\${SSL_PREFIX:-my-company}-mysql.crt
      --ssl-key=/etc/mysql/ssl/\${SSL_PREFIX:-my-company}-mysql.key
    networks:
      - ${DOCKER_NETWORK:-my-network}
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p\${MYSQL_ROOT_PASSWORD}"]
      interval: 30s
      timeout: 10s
      retries: 3

  # PostgreSQL Database
  postgres:
    image: postgres:17.6
    container_name: postgres
    restart: unless-stopped
    ports:
      - "\${POSTGRES_PORT:-5432}:5432"   # External:Internal PostgreSQL port
    environment:
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
      POSTGRES_USER: \${POSTGRES_USER}
      POSTGRES_DB: \${POSTGRES_DB}
      POSTGRES_INITDB_ARGS: "--auth-host=scram-sha-256"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./ssl/postgres:/etc/postgresql/ssl:ro
    command: >
      postgres
      -c ssl=on
      -c ssl_cert_file=/etc/postgresql/ssl/\${SSL_PREFIX:-my-company}-postgres.crt
      -c ssl_key_file=/etc/postgresql/ssl/\${SSL_PREFIX:-my-company}-postgres.key
      -c ssl_ca_file=/etc/postgresql/ssl/\${SSL_PREFIX:-my-company}-ca.crt
    networks:
        - ${DOCKER_NETWORK:-my-network}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \${POSTGRES_USER} -d \${POSTGRES_DB}"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Redis Cache
  redis:
    image: redis:8.2-alpine
    container_name: redis
    restart: unless-stopped
    ports:
      - "\${REDIS_PORT:-6379}:6379"   # External:Internal Redis port
      - "\${REDIS_SSL_PORT:-6380}:6380"   # External:Internal Redis TLS port
    environment:
      REDIS_PASSWORD: \${REDIS_PASSWORD}
    command: [
      "redis-server",
      "--appendonly", "yes",
      "--port", "6379",
      "--tls-port", "6380",
      "--requirepass", "\${REDIS_PASSWORD}",
      "--tls-cert-file", "/var/lib/redis/ssl/\${SSL_PREFIX:-my-company}-redis.crt",
      "--tls-key-file", "/var/lib/redis/ssl/\${SSL_PREFIX:-my-company}-redis.key",
      "--tls-ca-cert-file", "/var/lib/redis/ssl/\${SSL_PREFIX:-my-company}-ca.crt",
      "--tls-auth-clients", "no"
    ]
    volumes:
      - redis_data:/data
      - ./ssl/redis:/var/lib/redis/ssl:ro
    networks:
        - ${DOCKER_NETWORK:-my-network}
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "\${REDIS_PASSWORD}", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Fleet init
  fleet-init:
    image: fleetdm/fleet:latest
    platform: linux/amd64
    container_name: fleet-init
    depends_on:
      - mysql
    environment:
      FLEET_MYSQL_ADDRESS: mysql:3306
      FLEET_MYSQL_DATABASE: \${FLEET_MYSQL_DATABASE}
      FLEET_MYSQL_USERNAME: \${FLEET_MYSQL_USERNAME}
      FLEET_MYSQL_PASSWORD: \${FLEET_MYSQL_PASSWORD}
      FLEET_REDIS_ADDRESS: redis:6379
      FLEET_REDIS_PASSWORD: \${REDIS_PASSWORD}
    command: ["fleet", "prepare", "db"]
    restart: "no"
    networks:
      - \${DOCKER_NETWORK:-my-network}

  # Fleet server
  fleet:
    image: fleetdm/fleet:latest
    platform: linux/amd64
    container_name: fleet
    restart: unless-stopped
    depends_on:
      - fleet-init
      - mysql
      - redis
    environment:
      FLEET_MYSQL_ADDRESS: mysql:3306
      FLEET_MYSQL_DATABASE: \${FLEET_MYSQL_DATABASE}
      FLEET_MYSQL_USERNAME: \${FLEET_MYSQL_USERNAME}
      FLEET_MYSQL_PASSWORD: \${FLEET_MYSQL_PASSWORD}
      FLEET_REDIS_ADDRESS: redis:6379
      FLEET_REDIS_PASSWORD: \${REDIS_PASSWORD}
      FLEET_SERVER_ADDRESS: 0.0.0.0:8888
      FLEET_SERVER_TLS: "false"
      FLEET_SERVER_PRIVATE_KEY: \${FLEET_SERVER_PRIVATE_KEY}
      FLEET_MDM_WINDOWS_WSTEP_IDENTITY_CERT_BYTES: |
        \${FLEET_MDM_WINDOWS_WSTEP_IDENTITY_CERT_BYTES}
      FLEET_MDM_WINDOWS_WSTEP_IDENTITY_KEY_BYTES: |
        \${FLEET_MDM_WINDOWS_WSTEP_IDENTITY_KEY_BYTES}
    ports:
      - "8888:8080"
    networks:
        - ${DOCKER_NETWORK:-my-network}

      
  # Tinybird - Analytics (optional)
  tinybird:
    image: tinybirdco/tinybird-local:beta
    platform: linux/amd64
    container_name: tinybird
    restart: unless-stopped
    environment:
      TB_INFRA_TOKEN: \${TB_INFRA_TOKEN}
      TB_INFRA_WORKSPACE: \${TB_INFRA_WORKSPACE}
      TB_INFRA_ORGANIZATION: \${TB_INFRA_ORGANIZATION}
      TB_INFRA_USER: \${TB_INFRA_USER}
    volumes:
      - tinybird_clickhouse_data:/var/lib/clickhouse
      - tinybird_redis_data:/redis-data
    networks:
      - ${DOCKER_NETWORK:-my-network}

volumes:
  caddy_data:
  caddy_config:
  cloudbeaver_data:
  tinybird_clickhouse_data:
  tinybird_redis_data:
  mysql_data:
  postgres_data:
  redis_data:

networks:
  ${DOCKER_NETWORK:-my-network}:
    driver: bridge
EOF
    
    log_success "Docker Compose generated: $output_file"
}
