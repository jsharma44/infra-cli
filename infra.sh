#!/bin/bash

# 🚀 Optimized Infrastructure CLI
# Single, streamlined interface for all infrastructure management
# Consolidated from 12+ files into 1 main CLI + 4 core modules

set -e

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Set defaults
BACKUP_LOCAL_DIR=${BACKUP_LOCAL_DIR:-./backups}
DOCKER_NETWORK=${DOCKER_NETWORK:-my-network}

# Source core modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/core.sh"
source "$SCRIPT_DIR/scripts/services.sh"

# Source organized function files
source "$SCRIPT_DIR/scripts/backup.sh"
source "$SCRIPT_DIR/scripts/restore.sh"
source "$SCRIPT_DIR/scripts/remove.sh"
source "$SCRIPT_DIR/scripts/cron.sh"
source "$SCRIPT_DIR/scripts/logs.sh"

# Main CLI Interface
show_main_menu() {
    clear
    echo "🚀 Infrastructure CLI - Optimized"
    echo "================================="
    echo ""
    echo "🐳 Docker Management:"
    echo "1)  🐳 Install Docker"
    echo "2)  👤 Add Docker User"
    echo "3)  🔍 Check Docker User"
    echo "4)  🔍 Check Docker"
    echo "5)  📋 List Docker Services"
    echo "6)  🧹 Clean Everything (Volumes, Images, Containers, Networks)"
    echo ""
    echo "☁️  Cloud & Backup:"
    echo "7)  ☁️  Install AWS CLI"
    echo ""
    echo "📦 Service Management:"
    echo "8)  🏠 Setup Localhost (No Browser Warnings)"
    echo "9)  🌐 Setup Production (Let's Encrypt)"
    echo "10) 🎯 Deploy Individual Service"
    echo "11) ▶️  Start All Services"
    echo "12) 🛑 Stop All Services"
    echo "13) 🔄 Restart All Services"
    echo "14) 📊 Check Service Status"
    echo "15) 📋 View Service Logs"
    echo ""
    echo "🔧 System Management:"
    echo "16) 📊 System Overview"
    echo "17) 💾 Memory Usage"
    echo "18) 🖥️  CPU Usage"
    echo "19) 💿 Disk Usage"
    echo ""
    echo "🗄️  Backup & Restore:"
    echo "20) 📊 Backup All Databases"
    echo "21) 🐘 Backup MySQL Only"
    echo "22) 🐘 Backup PostgreSQL Only"
    echo "23) 🔴 Backup Redis Only"
    echo "24) 📊 Backup ClickHouse Only"
    echo "25) 🔄 Restore Database"
    echo "26) 📋 List Available Backups"
    echo "27) ⏰ Setup Automated Backups (Cron)"
    echo "28) 🧪 Test Backup System"
    echo "29) 📊 Backup Status & Info"
    echo "30) 🧹 Cleanup Old Backups"
    echo "31) 🗑️  Remove Automated Backups"
    echo "32) ⏰ Setup Cleanup Cron (Local & S3)"
    echo ""
    echo "🔐 SSL & Security:"
    echo "33) 🔧 Setup mkcert SSL (No Browser Warnings)"
    echo "34) 🔍 Check SSL Certificates"
    echo "35) 🔥 Firewall Status"
    echo ""
    echo "⏰ Cron Management:"
    echo "36) 📋 List All Cron Jobs"
    echo "37) 💾 Save Cron Jobs to File"
    echo "38) 📥 Restore Cron Jobs from File"
    echo "39) 🗑️  Remove All Cron Jobs"
    echo "40) 🧹 Remove Backup Cron Jobs Only"
    echo "41) 🔧 Edit Cron Jobs Manually"
    echo "42) 📄 View Cron Logs"
    echo "43) 🗑️  Remove Cron Logs"
    echo "44) 🧹 Clean Old Cron Logs"
    echo ""
    echo "❓ Help & Exit:"
    echo "45) ❓ Help"
    echo "46) 🚪 Exit"
    echo ""
}

# Deploy individual service
deploy_individual_service() {
    echo ""
    echo "🎯 Deploy Individual Service"
    echo "============================"
    echo ""
    echo "Choose environment:"
    echo "1) 🏠 Localhost (No Browser Warnings)"
    echo "2) 🌐 Production (Let's Encrypt)"
    echo "3) 🔧 Development (Environment Variables)"
    echo ""
    read -p "Enter environment choice (1-3): " env_choice
    
    case $env_choice in
        1) local environment="localhost" ;;
        2) 
            # Use environment variables if available, otherwise prompt
            if [ -z "${DOMAIN:-}" ]; then
                read -p "Enter your domain (e.g., yourdomain.com): " domain
            else
                domain="${DOMAIN}"
                echo "Using domain from environment: $domain"
            fi
            
            if [ -z "${EMAIL:-}" ]; then
                read -p "Enter your email for Let's Encrypt: " email
            else
                email="${EMAIL}"
                echo "Using email from environment: $email"
            fi
            local environment="production"
            ;;
        3) local environment="development" ;;
        *) echo "❌ Invalid choice"; return 1 ;;
    esac
    
    echo ""
    echo "Choose service to deploy:"
    echo "1) 🗄️  CloudBeaver (Database Management)"
    echo "2) 🚀 Fleet (Device Management)"
    echo "3) 📊 Tinybird (Analytics)"
    echo "4) 🐘 MySQL (Database)"
    echo "5) 🐘 PostgreSQL (Database)"
    echo "6) 🔴 Redis (Cache)"
    echo ""
    read -p "Enter service choice (1-6): " service_choice
    
    case $service_choice in
        1) local service="cloudbeaver" ;;
        2) local service="fleet" ;;
        3) local service="tinybird" ;;
        4) local service="mysql" ;;
        5) local service="postgres" ;;
        6) local service="redis" ;;
        *) echo "❌ Invalid choice"; return 1 ;;
    esac
    
    echo ""
    echo "🚀 Deploying $service for $environment environment..."
    
    # Setup infrastructure first
    setup_infrastructure "$environment" "$domain" "$email"
    
    # Start specific service
    log_info "Starting $service service..."
    docker compose up -d "$service"
    
    if [ $? -eq 0 ]; then
        log_success "$service service started successfully!"
        show_service_urls "$environment" "$service"
    else
        log_error "Failed to start $service service"
    fi
}

# Show service URLs
show_service_urls() {
    local environment="$1"
    local service="${2:-all}"
    
    echo ""
    echo "🌐 Access your services:"
    
    if [ "$environment" = "localhost" ]; then
        case $service in
            "cloudbeaver"|"all") echo "   • CloudBeaver: https://cloudbeaver.localhost" ;;
            "fleet"|"all") echo "   • Fleet: https://fleet.localhost" ;;
            "tinybird"|"all") echo "   • Tinybird: https://tinybird.localhost" ;;
            "mysql"|"all") echo "   • MySQL: https://mysql.localhost" ;;
            "postgres"|"all") echo "   • PostgreSQL: https://postgres.localhost" ;;
            "redis"|"all") echo "   • Redis: https://redis.localhost" ;;
        esac
        echo "   • Health: https://localhost:8080/health"
    elif [ "$environment" = "production" ] && [ -n "$domain" ]; then
        case $service in
            "cloudbeaver"|"all") echo "   • CloudBeaver: https://cloudbeaver.$domain" ;;
            "fleet"|"all") echo "   • Fleet: https://fleet.$domain" ;;
            "tinybird"|"all") echo "   • Tinybird: https://tinybird.$domain" ;;
        esac
    else
        echo "   • Check your Caddyfile for configured domains"
    fi
}

# Show help
show_help() {
    echo "❓ Infrastructure CLI Help"
    echo "========================="
    echo ""
    echo "This optimized CLI provides comprehensive infrastructure management:"
    echo ""
    echo "🐳 Docker Management:"
    echo "  • Install and configure Docker"
    echo "  • Manage Docker users and permissions"
    echo "  • Check Docker installation and status"
    echo "  • List Docker services and containers"
    echo ""
    echo "📦 Service Management:"
    echo "  • Deploy services for localhost, production, or development"
    echo "  • Start, stop, and restart services"
    echo "  • Monitor service status and logs"
    echo "  • Deploy individual services"
    echo ""
    echo "🔧 System Management:"
    echo "  • Monitor system resources (CPU, memory, disk)"
    echo "  • View system overview and statistics"
    echo "  • Check system performance"
    echo ""
    echo "🗄️  Backup & Restore:"
    echo "  • Backup all databases (MySQL, PostgreSQL, Redis, ClickHouse)"
    echo "  • Backup individual databases"
    echo "  • Restore databases from backups"
    echo "  • Setup automated backups with cron"
    echo "  • Manage backup schedules and cleanup"
    echo "  • Test backup system functionality"
    echo ""
    echo "🔐 SSL & Security:"
    echo "  • Setup mkcert for localhost SSL (no browser warnings)"
    echo "  • Check SSL certificates and security status"
    echo "  • Monitor firewall rules"
    echo ""
    echo "🚀 Quick Start:"
    echo "  1. ./infra.sh (run this script)"
    echo "  2. Choose option 6 (Setup Localhost)"
    echo "  3. Choose option 9 (Start All Services)"
    echo "  4. Access services via HTTPS!"
    echo ""
    echo "📋 All Available Options:"
    echo "  Docker Management: 1-6"
    echo "  Service Management: 7-14"
    echo "  System Management: 15-18"
    echo "  Backup & Restore: 19-31"
    echo "  SSL & Security: 32-34"
    echo "  Cron Management: 35-43"
    echo "  Help & Exit: 44-45"
    echo ""
}

# Execute menu option
execute_option() {
    local choice="$1"
    case $choice in
            # Docker Management
            1)
                install_docker
                ;;
            2)
                add_docker_user
                ;;
            3)
                check_docker_user
                ;;
            4)
                check_docker
                ;;
            5)
                list_docker_services
                ;;
            6)
                clean_docker_everything
                ;;
            7)
                install_aws_cli
                ;;
            
            # Service Management
            8)
                log_info "Setting up localhost infrastructure (no browser warnings)"
                setup_infrastructure "localhost"
                ;;
            9)
                # Use environment variables if available, otherwise prompt
                if [ -z "${DOMAIN:-}" ]; then
                    read -p "Enter your domain (e.g., yourdomain.com): " domain
                else
                    domain="${DOMAIN}"
                    echo "Using domain from environment: $domain"
                fi
                
                if [ -z "${EMAIL:-}" ]; then
                    read -p "Enter your email for Let's Encrypt: " email
                else
                    email="${EMAIL}"
                    echo "Using email from environment: $email"
                fi
                
                log_info "Setting up production infrastructure with Let's Encrypt and Cloudflare DNS"
                setup_infrastructure "production" "$domain" "$email"
                ;;
            10)
                deploy_individual_service
                ;;
            11)
                log_info "Starting all services"
                docker compose up -d
                if [ $? -eq 0 ]; then
                    log_success "All services started successfully!"
                    show_service_urls "localhost" "all"
                else
                    log_error "Failed to start services"
                fi
                ;;
            12)
                log_info "Stopping all services"
                docker compose down
                log_success "All services stopped"
                ;;
            13)
                log_info "Restarting all services"
                docker compose restart
                log_success "All services restarted"
                ;;
            14)
                log_info "Checking service status"
                docker compose ps
                echo ""
                echo "🔍 Service health checks:"
                docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
                ;;
            15)
                log_info "Showing service logs"
                docker compose logs -f
                ;;
            
            # System Management
            16)
                show_system_overview
                ;;
            17)
                show_memory_usage
                ;;
            18)
                show_cpu_usage
                ;;
            19)
                show_disk_usage
                ;;
            
            # Backup & Restore
            20)
                backup_all_databases
                ;;
            21)
                backup_mysql_only
                ;;
            22)
                backup_postgres_only
                ;;
            23)
                backup_redis_only
                ;;
            24)
                backup_clickhouse_only
                ;;
            25)
                restore_database
                ;;
            26)
                list_backups
                ;;
            27)
                setup_automated_backups
                ;;
            28)
                test_backup_system
                ;;
            29)
                show_backup_status
                ;;
            30)
                cleanup_old_backups
                ;;
            31)
                remove_automated_backups
                ;;
            32)
                setup_cleanup_cron
                ;;
            
            # SSL & Security
            33)
                setup_mkcert_ssl
                ;;
            34)
                check_ssl_certificates
                ;;
            35)
                show_firewall_status
                ;;
            
            # Cron Management
            36)
                list_all_cron_jobs
                ;;
            37)
                save_cron_jobs
                ;;
            38)
                restore_cron_jobs
                ;;
            39)
                remove_all_cron_jobs
                ;;
            40)
                remove_backup_cron_jobs
                ;;
            41)
                edit_cron_jobs_manually
                ;;
            42)
                view_cron_logs
                ;;
            43)
                remove_cron_logs
                ;;
            44)
                clean_old_cron_logs
                ;;
            
            # Help & Exit
            45)
                show_help
                ;;
            46)
                echo "👋 Goodbye!"
                exit 0
                ;;
            *)
                echo "❌ Invalid choice. Please enter 1-46."
                ;;
        esac
}

# Main execution loop
main() {
    # Handle command line arguments
    if [ $# -gt 0 ]; then
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            [0-9]*)
                choice="$1"
                ;;
            *)
                echo "❌ Invalid argument: $1"
                echo "Usage: $0 [option_number] or $0 --help"
                exit 1
                ;;
        esac
        
        # Execute the chosen option
        execute_option "$choice"
    else
        while true; do
            show_main_menu
            read -p "Enter your choice (1-46): " choice
            
            # Execute the chosen option
            execute_option "$choice"
            
            echo ""
            read -p "Press Enter to continue..."
        done
    fi
}

# Call main function with all arguments
main "$@"
