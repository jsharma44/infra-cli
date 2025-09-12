#!/bin/bash

# 🚀 Optimized Infrastructure Setup
# Single command setup for all environments
# Simplified from multiple setup scripts

set -e

# Load environment variables and core functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/scripts/env.sh"
source "$SCRIPT_DIR/scripts/core.sh"

# Default values (using env.sh variables)
ENVIRONMENT="${DEPLOYMENT_ENV:-local}"
DOMAIN="${DOMAIN:-}"
EMAIL="${EMAIL:-}"
ACTION="setup"

# Show help
show_help() {
    echo "🚀 Infrastructure Setup - Optimized"
    echo "==================================="
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -e, --environment    Environment: local, production, development (default: local)"
    echo "  -d, --domain         Domain for production (e.g., yourdomain.com)"
    echo "  -m, --email          Email for Let's Encrypt (e.g., admin@yourdomain.com)"
    echo "  -a, --action         Action: setup, start, stop, restart, status, logs (default: setup)"
    echo "  -h, --help           Show this help"
    echo ""
    echo "Examples:"
    echo "  # Localhost setup (no browser warnings)"
    echo "  $0"
    echo ""
    echo "  # Production setup with Let's Encrypt"
    echo "  $0 -e production -d yourdomain.com -m admin@yourdomain.com"
    echo ""
    echo "  # Development setup using .env variables"
    echo "  $0 -e development"
    echo ""
    echo "  # Start services"
    echo "  $0 -a start"
    echo ""
    echo "  # Check status"
    echo "  $0 -a status"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -m|--email)
            EMAIL="$2"
            shift 2
            ;;
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Execute action
case "$ACTION" in
    "setup")
        log_info "Setting up infrastructure for environment: $ENVIRONMENT"
        setup_infrastructure "$ENVIRONMENT" "$DOMAIN" "$EMAIL"
        ;;
        
    "start")
        log_info "Starting all services..."
        docker compose up -d
        if [ $? -eq 0 ]; then
            log_success "All services started successfully!"
            echo ""
            echo "🌐 Access your services:"
            if [ "$ENVIRONMENT" = "local" ]; then
                echo "   • CloudBeaver: https://cloudbeaver.localhost"
                echo "   • Fleet: https://fleet.localhost"
                echo "   • Tinybird: https://tinybird.localhost"
                echo "   • PostgreSQL: https://postgres.localhost"
                echo "   • MySQL: https://mysql.localhost"
                echo "   • Redis: https://redis.localhost"
                echo "   • Health: https://localhost:8080/health"
            elif [ "$ENVIRONMENT" = "production" ] && [ -n "$DOMAIN" ]; then
                echo "   • CloudBeaver: https://cloudbeaver.$DOMAIN"
                echo "   • Fleet: https://fleet.$DOMAIN"
                echo "   • Tinybird: https://tinybird.$DOMAIN"
                echo "   • Health: https://health.$DOMAIN/health"
            else
                echo "   • Check your Caddyfile for configured domains"
            fi
        else
            log_error "Failed to start services"
            exit 1
        fi
        ;;
        
    "stop")
        log_info "Stopping all services..."
        docker compose down
        log_success "All services stopped"
        ;;
        
    "restart")
        log_info "Restarting all services..."
        docker compose restart
        log_success "All services restarted"
        ;;
        
    "status")
        log_info "Checking service status..."
        docker compose ps
        echo ""
        echo "🔍 Service health checks:"
        docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
        ;;
        
    "logs")
        log_info "Showing service logs..."
        docker compose logs -f
        ;;
        
    *)
        log_error "Unknown action: $ACTION"
        show_help
        exit 1
        ;;
esac
