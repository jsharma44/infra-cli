#!/bin/bash

# 🔧 Service Management Functions
# Docker, SSL, monitoring, and service-specific functions
# Consolidated from multiple function files

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/scripts/env.sh"

# =============================================================================
# SSL MANAGEMENT FUNCTIONS
# =============================================================================

# Setup mkcert SSL
setup_mkcert_ssl() {
    echo "🔐 Setting up mkcert SSL (No Browser Warnings)"
    echo "=============================================="
    echo ""
    
    # Check if mkcert is installed
    if ! command -v mkcert &> /dev/null; then
        echo "❌ mkcert is not installed!"
        echo ""
        echo "📋 Install mkcert:"
        echo "   macOS: brew install mkcert"
        echo "   Linux: https://github.com/FiloSottile/mkcert#installation"
        echo "   Windows: https://github.com/FiloSottile/mkcert#installation"
        return 0
    fi
    
    # Create SSL directory
    mkdir -p ssl/mkcert
    
    # Install the local CA (if not already installed)
    echo "📝 Installing local CA certificate..."
    mkcert -install
    
    # Generate certificates for all localhost domains
    echo "📝 Generating localhost certificates..."
    mkcert -cert-file ssl/mkcert/localhost.pem -key-file ssl/mkcert/localhost-key.pem \
        localhost \
        *.localhost \
        cb.localhost \
        fleet.localhost \
        tb.localhost \
        postgres.localhost \
        mysql.localhost \
        redis.localhost \
        127.0.0.1 \
        ::1
    
    # Set proper permissions
    chmod 644 ssl/mkcert/localhost.pem
    chmod 600 ssl/mkcert/localhost-key.pem
    
    echo ""
    echo "✅ SSL certificates generated successfully with mkcert!"
    echo ""
    echo "🔧 Next steps:"
    echo "1. Restart your browser (if needed)"
    echo "2. Visit https://cloudbeaver.localhost"
    echo "3. You should see no SSL warnings! 🎉"
    echo ""
    echo "📁 Certificate files:"
    echo "   Certificate: ssl/mkcert/localhost.pem"
    echo "   Private Key: ssl/mkcert/localhost-key.pem"
}

# Check SSL certificates
check_ssl_certificates() {
    echo "🔐 SSL Certificate Status"
    echo "========================="
    echo ""
    
    # Check if Caddy is running
    if ! docker ps | grep -q caddy; then
        echo "❌ Caddy is not running. Cannot access certificates."
        return 0
    fi
    
    echo "📋 Available Certificates:"
    echo ""
    
    # List certificates from Caddy
    echo "🌐 Caddy-managed certificates:"
    docker exec caddy caddy list-certificates 2>/dev/null | while read line; do
        if [[ $line =~ ^[a-zA-Z0-9.-]+$ ]]; then
            echo "  • $line"
        fi
    done
    echo ""
    
    # List local certificate files
    echo "📁 Local certificate files:"
    if [ -d "ssl" ]; then
        for service_dir in ssl/*/; do
            if [ -d "$service_dir" ]; then
                service_name=$(basename "$service_dir")
                echo "  📂 $service_name:"
                
                # Check for certificate files
                if [ -f "$service_dir/cert.pem" ] || [ -f "$service_dir/localhost.pem" ]; then
                    local cert_file="$service_dir/cert.pem"
                    if [ ! -f "$cert_file" ]; then
                        cert_file="$service_dir/localhost.pem"
                    fi
                    
                    local cert_info=$(openssl x509 -in "$cert_file" -text -noout 2>/dev/null)
                    local subject=$(echo "$cert_info" | grep "Subject:" | head -1)
                    local issuer=$(echo "$cert_info" | grep "Issuer:" | head -1)
                    local not_after=$(echo "$cert_info" | grep "Not After" | head -1)
                    
                    echo "    ✅ Certificate exists"
                    echo "    $subject"
                    echo "    $issuer"
                    echo "    $not_after"
                else
                    echo "    ❌ No certificate found"
                fi
                echo ""
            fi
        done
    else
        echo "  ❌ No SSL directory found"
    fi
    
    # Check mkcert CA
    echo "🔍 mkcert CA Status:"
    if command -v mkcert &> /dev/null; then
        local ca_root=$(mkcert -CAROOT)
        if [ -f "$ca_root/rootCA.pem" ]; then
            echo "  ✅ mkcert CA is installed"
            echo "  📁 CA Location: $ca_root"
        else
            echo "  ❌ mkcert CA is not installed"
        fi
    else
        echo "  ❌ mkcert is not installed"
    fi
}

# =============================================================================
# FIREWALL MANAGEMENT FUNCTIONS
# =============================================================================

# Show firewall status
show_firewall_status() {
    echo "🔥 Firewall Status"
    echo "=================="
    echo ""
    
    if ! command -v ufw >/dev/null 2>&1; then
        echo "❌ UFW is not installed"
        echo "Install with: sudo apt-get install ufw"
        return 0
    fi
    
    echo "🔥 UFW Status:"
    sudo ufw status verbose
    echo ""
    
    echo "📋 Numbered Rules:"
    sudo ufw status numbered
    echo ""
    
    echo "📊 Rule Statistics:"
    echo "Total rules: $(sudo ufw status | grep -c '^\[.*\]')"
    echo "Active rules: $(sudo ufw status | grep -c '^\[.*\]' | grep -v '^0$' || echo '0')"
}

# =============================================================================
# DOCKER SERVICE FUNCTIONS
# =============================================================================

# List Docker services
list_docker_services() {
    echo "🐳 Docker Services"
    echo "=================="
    echo ""
    
    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ Docker is not installed"
        return 0
    fi
    
    echo "📋 Running Containers:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    echo "📊 Container Statistics:"
    echo "Running: $(docker ps -q | wc -l)"
    echo "Total: $(docker ps -a -q | wc -l)"
    echo ""
    
    echo "💾 Images:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    echo ""
    
    echo "🌐 Networks:"
    docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"
    echo ""
    
    echo "💿 Volumes:"
    docker volume ls --format "table {{.Name}}\t{{.Driver}}"
}

# Stop all services
stop_all_services() {
    echo "🛑 Stopping All Services"
    echo "========================"
    echo ""
    
    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ Docker is not installed"
        return 0
    fi
    
    log_info "Stopping all Docker services..."
    docker compose down
    
    if [ $? -eq 0 ]; then
        log_success "All services stopped successfully"
    else
        log_error "Failed to stop some services"
    fi
}

# Start all services
start_all_services() {
    echo "▶️  Starting All Services"
    echo "========================"
    echo ""
    
    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ Docker is not installed"
        return 0
    fi
    
    log_info "Starting all Docker services..."
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        log_success "All services started successfully"
        echo ""
        echo "🌐 Access your services:"
        echo "   • CloudBeaver: https://cloudbeaver.localhost"
        echo "   • Fleet: https://fleet.localhost"
        echo "   • Tinybird: https://tinybird.localhost"
        echo "   • PostgreSQL: https://postgres.localhost"
        echo "   • MySQL: https://mysql.localhost"
        echo "   • Redis: https://redis.localhost"
        echo "   • Health: https://localhost:8080/health"
    else
        log_error "Failed to start services"
    fi
}

# Restart all services
restart_all_services() {
    echo "🔄 Restarting All Services"
    echo "=========================="
    echo ""
    
    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ Docker is not installed"
        return 0
    fi
    
    log_info "Restarting all Docker services..."
    docker compose restart
    
    if [ $? -eq 0 ]; then
        log_success "All services restarted successfully"
    else
        log_error "Failed to restart some services"
    fi
}

# =============================================================================
# SERVICE HEALTH FUNCTIONS
# =============================================================================

# Check service health
check_service_health() {
    local service="${1:-all}"
    
    echo "🏥 Service Health Check"
    echo "======================="
    echo ""
    
    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ Docker is not installed"
        return 0
    fi
    
    if [ "$service" = "all" ]; then
        echo "📊 All Services Status:"
        docker compose ps
        echo ""
        
        echo "🔍 Health Check Details:"
        docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "🔍 $service Service Status:"
        docker compose ps "$service"
        echo ""
        
        echo "📋 $service Logs (last 20 lines):"
        docker compose logs --tail 20 "$service"
    fi
}

# Test service connectivity
test_service_connectivity() {
    local service="${1:-cloudbeaver}"
    local port="${2:-443}"
    
    echo "🌐 Testing $service Connectivity"
    echo "================================"
    echo ""
    
    case $service in
        "cloudbeaver")
            local url="https://cloudbeaver.localhost"
            ;;
        "fleet")
            local url="https://fleet.localhost"
            ;;
        "tinybird")
            local url="https://tinybird.localhost"
            ;;
        "mysql")
            local url="https://mysql.localhost"
            ;;
        "postgres")
            local url="https://postgres.localhost"
            ;;
        "redis")
            local url="https://redis.localhost"
            ;;
        *)
            echo "❌ Unknown service: $service"
            return 0
            ;;
    esac
    
    echo "🔍 Testing connection to $url..."
    
    if curl -I -k "$url" 2>/dev/null | grep -q "HTTP/2 200"; then
        echo "✅ $service is accessible and responding"
    else
        echo "❌ $service is not accessible or not responding"
        echo "💡 Check if the service is running: docker compose ps"
        echo "💡 Check service logs: docker compose logs $service"
    fi
}

# =============================================================================
# SERVICE CONFIGURATION FUNCTIONS
# =============================================================================

# Regenerate service configuration
regenerate_service_config() {
    local service="${1:-all}"
    
    echo "🔄 Regenerating Service Configuration"
    echo "===================================="
    echo ""
    
    case $service in
        "caddyfile"|"all")
            log_info "Regenerating Caddyfile..."
            generate_caddyfile "localhost"
            ;;
        "docker-compose"|"all")
            log_info "Regenerating Docker Compose..."
            generate_docker_compose "localhost"
            ;;
        "ssl"|"all")
            log_info "Regenerating SSL certificates..."
            setup_mkcert_ssl
            ;;
        *)
            echo "❌ Unknown service: $service"
            echo "Available services: caddyfile, docker-compose, ssl, all"
            return 0
            ;;
    esac
    
    log_success "Service configuration regenerated"
}

# =============================================================================
# SERVICE CLEANUP FUNCTIONS
# =============================================================================

# Clean up service data
cleanup_service_data() {
    local service="${1:-all}"
    
    echo "🧹 Cleaning Up Service Data"
    echo "==========================="
    echo ""
    
    if [ "$service" = "all" ]; then
        echo "⚠️  This will remove ALL service data including databases!"
        read -p "Are you sure? Type 'yes' to confirm: " confirm
        
        if [ "$confirm" != "yes" ]; then
            echo "❌ Cleanup cancelled"
            return 0
        fi
        
        log_info "Stopping all services..."
        docker compose down
        
        log_info "Removing all volumes..."
        docker volume prune -f
        
        log_info "Removing all containers..."
        docker container prune -f
        
        log_success "All service data cleaned up"
    else
        echo "⚠️  This will remove $service data including any databases!"
        read -p "Are you sure? Type 'yes' to confirm: " confirm
        
        if [ "$confirm" != "yes" ]; then
            echo "❌ Cleanup cancelled"
            return 0
        fi
        
        log_info "Stopping $service service..."
        docker compose stop "$service"
        
        log_info "Removing $service volume..."
        docker volume rm "${service}_data" 2>/dev/null || true
        
        log_success "$service data cleaned up"
    fi
}
