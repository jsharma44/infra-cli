#!/bin/bash

# 🗄️ Backup Functions
# Core backup functionality only
# Cleaned up and organized

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

# Load utility functions for logging
if [ -f "$SCRIPT_DIR/scripts/core.sh" ]; then
    source "$SCRIPT_DIR/scripts/core.sh"
fi

# =============================================================================
# BACKUP CONFIGURATION
# =============================================================================

# Backup directory
BACKUP_LOCAL_DIR="${BACKUP_LOCAL_DIR:-./backups}"

# Backup compression
BACKUP_COMPRESSION="${BACKUP_COMPRESSION:-true}"

# Backup retention days
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"

# S3 configuration
S3_BACKUP_ENABLED="${S3_BACKUP_ENABLED:-false}"
S3_BUCKET_NAME="${S3_BUCKET_NAME:-}"
S3_REGION="${S3_REGION:-us-east-1}"
S3_ENDPOINT_URL="${S3_ENDPOINT_URL:-}"

# =============================================================================
# BACKUP FUNCTIONS
# =============================================================================

# Backup MySQL only
backup_mysql_only() {
    echo "🐘 Starting MySQL Backup"
    echo "========================"
    echo ""
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_date=$(date +"%Y-%m-%d")
    local backup_dir="$BACKUP_LOCAL_DIR/$backup_date"
    
    mkdir -p "$backup_dir"
    
    if docker ps | grep -q mysql; then
        log_info "Backing up MySQL database..."
        backup_mysql "$backup_dir" "$timestamp"
        
        # Upload to S3 if enabled
        if [ "$S3_BACKUP_ENABLED" = "true" ]; then
            log_info "Uploading MySQL backup to S3..."
            local backup_file="$backup_dir/mysql_backup_$timestamp.sql"
            if [ "$BACKUP_COMPRESSION" = "true" ]; then
                backup_file="${backup_file}.gz"
            fi
            upload_single_backup_to_s3 "$backup_file" "$timestamp" "mysql"
        fi
    else
        log_warning "MySQL container not running, skipping backup"
        return 0
    fi
}

# Backup PostgreSQL only
backup_postgres_only() {
    echo "🐘 Starting PostgreSQL Backup"
    echo "============================="
    echo ""
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_date=$(date +"%Y-%m-%d")
    local backup_dir="$BACKUP_LOCAL_DIR/$backup_date"
    
    mkdir -p "$backup_dir"
    
    if docker ps | grep -q postgres; then
        log_info "Backing up PostgreSQL database..."
        backup_postgres "$backup_dir" "$timestamp"
        
        # Upload to S3 if enabled
        if [ "$S3_BACKUP_ENABLED" = "true" ]; then
            log_info "Uploading PostgreSQL backup to S3..."
            local backup_file="$backup_dir/postgres_backup_$timestamp.sql"
            if [ "$BACKUP_COMPRESSION" = "true" ]; then
                backup_file="${backup_file}.gz"
            fi
            upload_single_backup_to_s3 "$backup_file" "$timestamp" "postgres"
        fi
    else
        log_warning "PostgreSQL container not running, skipping backup"
        return 0
    fi
}

# Backup Redis only
backup_redis_only() {
    echo "🔴 Starting Redis Backup"
    echo "========================"
    echo ""
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_date=$(date +"%Y-%m-%d")
    local backup_dir="$BACKUP_LOCAL_DIR/$backup_date"
    
    mkdir -p "$backup_dir"
    
    if docker ps | grep -q redis; then
        log_info "Backing up Redis database..."
        backup_redis "$backup_dir" "$timestamp"
        
        # Upload to S3 if enabled
        if [ "$S3_BACKUP_ENABLED" = "true" ]; then
            log_info "Uploading Redis backup to S3..."
            local backup_file="$backup_dir/redis_backup_$timestamp.rdb"
            if [ "$BACKUP_COMPRESSION" = "true" ]; then
                backup_file="${backup_file}.gz"
            fi
            upload_single_backup_to_s3 "$backup_file" "$timestamp" "redis"
        fi
    else
        log_warning "Redis container not running, skipping backup"
        return 0
    fi
}

# Backup ClickHouse only
backup_clickhouse_only() {
    echo "📊 Starting ClickHouse Backup"
    echo "============================="
    echo ""
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_date=$(date +"%Y-%m-%d")
    local backup_dir="$BACKUP_LOCAL_DIR/$backup_date"
    
    mkdir -p "$backup_dir"
    
    if docker ps | grep -q tinybird; then
        log_info "Backing up ClickHouse database (via Tinybird)..."
        backup_clickhouse "$backup_dir" "$timestamp"
    else
        log_warning "Tinybird container not running, skipping ClickHouse backup"
        return 0
    fi
}

# Backup all databases
backup_all_databases() {
    echo "🗄️  Starting Backup of All Databases"
    echo "===================================="
    echo ""
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_date=$(date +"%Y-%m-%d")
    
    log_info "Starting comprehensive database backup - $timestamp"
    
    # Create backup directory for this run
    local backup_dir="$BACKUP_LOCAL_DIR/$backup_date"
    mkdir -p "$backup_dir"
    
    # Backup MySQL
    if docker ps | grep -q mysql; then
        log_info "Backing up MySQL database..."
        backup_mysql "$backup_dir" "$timestamp"
    else
        log_warning "MySQL container not running, skipping backup"
    fi
    
    # Backup PostgreSQL
    if docker ps | grep -q postgres; then
        log_info "Backing up PostgreSQL database..."
        backup_postgres "$backup_dir" "$timestamp"
    else
        log_warning "PostgreSQL container not running, skipping backup"
    fi
    
    # Backup Redis
    if docker ps | grep -q redis; then
        log_info "Backing up Redis database..."
        backup_redis "$backup_dir" "$timestamp"
    else
        log_warning "Redis container not running, skipping backup"
    fi
    
    # Backup ClickHouse (if available)
    if docker ps | grep -q tinybird; then
        log_info "Backing up ClickHouse database..."
        backup_clickhouse "$backup_dir" "$timestamp"
    else
        log_warning "ClickHouse container not running, skipping backup"
    fi
    
    # Compress backup directory (keep individual files for 30 days)
    if [ "$BACKUP_COMPRESSION" = "true" ]; then
        log_info "Compressing backup directory..."
        tar -czf "$BACKUP_LOCAL_DIR/backup_$timestamp.tar.gz" -C "$BACKUP_LOCAL_DIR" "$backup_date"
        # Keep individual files for 30 days (don't remove backup_dir)
        log_success "Backup compressed: backup_$timestamp.tar.gz"
        log_info "Individual database files kept in: $backup_dir"
    fi
    
    # Upload to S3 if enabled
    if [ "$S3_BACKUP_ENABLED" = "true" ]; then
        log_info "Uploading backup to S3..."
        upload_backup_to_s3 "$timestamp"
    fi
    
    # Cleanup old backups
    cleanup_old_backups
    
    log_success "All database backups completed successfully!"
    echo ""
    echo "📁 Backup location: $BACKUP_LOCAL_DIR"
    echo "📊 Backup size: $(du -sh "$BACKUP_LOCAL_DIR" | cut -f1)"
}

# Backup MySQL database
backup_mysql() {
    local backup_dir="$1"
    local timestamp="$2"
    local backup_file="$backup_dir/mysql_backup_$timestamp.sql"
    
    # Create MySQL backup
    docker exec mysql mysqldump -u root -p"${MYSQL_ROOT_PASSWORD:-password}" --all-databases > "$backup_file"
    
    if [ $? -eq 0 ]; then
        if [ "$BACKUP_COMPRESSION" = "true" ]; then
            gzip "$backup_file"
            backup_file="${backup_file}.gz"
        fi
        log_success "MySQL backup completed: $(basename "$backup_file")"
    else
        log_error "MySQL backup failed"
        return 0
    fi
}

# Backup PostgreSQL database
backup_postgres() {
    local backup_dir="$1"
    local timestamp="$2"
    local backup_file="$backup_dir/postgres_backup_$timestamp.sql"
    
    # Create PostgreSQL backup
    PGPASSWORD="${POSTGRES_PASSWORD}" docker exec postgres pg_dumpall -U "${POSTGRES_USER}" > "$backup_file"
    
    if [ $? -eq 0 ]; then
        if [ "$BACKUP_COMPRESSION" = "true" ]; then
            gzip "$backup_file"
            backup_file="${backup_file}.gz"
        fi
        log_success "PostgreSQL backup completed: $(basename "$backup_file")"
    else
        log_error "PostgreSQL backup failed"
        return 0
    fi
}

# Backup Redis database
backup_redis() {
    local backup_dir="$1"
    local timestamp="$2"
    local backup_file="$backup_dir/redis_backup_$timestamp.rdb"
    
    # Create RDB snapshot (with TLS on port 6380 and authentication)
    docker exec redis redis-cli --tls --insecure -p 6380 -a "${REDIS_PASSWORD:-password}" BGSAVE
    
    # Wait for background save to complete (simple approach)
    sleep 3
    
    # Copy RDB file
    docker cp redis:/data/dump.rdb "$backup_file"
    
    if [ "$BACKUP_COMPRESSION" = "true" ]; then
        gzip "$backup_file"
        backup_file="${backup_file}.gz"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "Redis backup completed: $(basename "$backup_file")"
    else
        log_error "Redis backup failed"
        return 0
    fi
}

# Backup ClickHouse database
backup_clickhouse() {
    local backup_dir="$1"
    local timestamp="$2"
    local backup_file="$backup_dir/clickhouse_backup_$timestamp.sql"
    
    # Create comprehensive ClickHouse backup via Tinybird container
    echo "-- ClickHouse Database Backup" > "$backup_file"
    echo "-- Generated: $(date)" >> "$backup_file"
    echo "" >> "$backup_file"
    
    # Get all databases and their data
    docker exec tinybird clickhouse-client --query "SHOW DATABASES" | while read db; do
        if [ "$db" != "system" ] && [ "$db" != "INFORMATION_SCHEMA" ] && [ "$db" != "information_schema" ]; then
            echo "-- Database: $db" >> "$backup_file"
            echo "CREATE DATABASE IF NOT EXISTS \`$db\`;" >> "$backup_file"
            echo "USE \`$db\`;" >> "$backup_file"
            echo "" >> "$backup_file"
            
            # Get all tables in this database
            docker exec tinybird clickhouse-client --query "SHOW TABLES FROM \`$db\`" | while read table; do
                if [ -n "$table" ]; then
                    echo "-- Table: $db.$table" >> "$backup_file"
                    # Get table structure
                    docker exec tinybird clickhouse-client --query "SHOW CREATE TABLE \`$db\`.\`$table\`" >> "$backup_file"
                    echo "" >> "$backup_file"
                    # Get table data
                    docker exec tinybird clickhouse-client --query "SELECT * FROM \`$db\`.\`$table\` FORMAT SQLInsert" >> "$backup_file"
                    echo "" >> "$backup_file"
                fi
            done
        fi
    done
    
    if [ $? -eq 0 ]; then
        if [ "$BACKUP_COMPRESSION" = "true" ]; then
            gzip "$backup_file"
            backup_file="${backup_file}.gz"
        fi
        log_success "ClickHouse backup completed: $(basename "$backup_file")"
    else
        log_error "ClickHouse backup failed"
        return 0
    fi
}

# List all backups
list_backups() {
    echo "📋 Available Backups"
    echo "==================="
    echo ""
    
    if [ ! -d "$BACKUP_LOCAL_DIR" ]; then
        echo "❌ No backup directory found: $BACKUP_LOCAL_DIR"
        return 0
    fi
    
    echo "📁 Backup Directory: $BACKUP_LOCAL_DIR"
    echo ""
    
    # List backups by date
    echo "📅 Backups by Date:"
    find "$BACKUP_LOCAL_DIR" -type d -name "*-*-*" | sort -r | while read date_dir; do
        local date_name=$(basename "$date_dir")
        local dir_size=$(du -sh "$date_dir" | cut -f1)
        echo "  📂 $date_name ($dir_size)"
        
        # List files in date directory
        find "$date_dir" -type f | while read file; do
            local filename=$(basename "$file")
            local file_size=$(du -h "$file" | cut -f1)
            echo "    📄 $filename ($file_size)"
        done
    done
    
    # List compressed backups
    echo ""
    echo "📦 Compressed Backups:"
    find "$BACKUP_LOCAL_DIR" -name "backup_*.tar.gz" -type f | sort -r | while read backup_file; do
        local filename=$(basename "$backup_file")
        local file_size=$(du -h "$backup_file" | cut -f1)
        local file_date=$(stat -c %y "$backup_file" 2>/dev/null || stat -f %Sm "$backup_file" 2>/dev/null)
        echo "  📦 $filename ($file_size) - $file_date"
    done
    
    echo ""
    echo "📊 Total backup size: $(du -sh "$BACKUP_LOCAL_DIR" | cut -f1)"
}

# Upload backup to S3
upload_backup_to_s3() {
    local timestamp="$1"
    local backup_file="$BACKUP_LOCAL_DIR/backup_$timestamp.tar.gz"
    
    if [ ! -f "$backup_file" ]; then
        log_error "Backup file not found: $backup_file"
        return 0
    fi
    
    if ! command -v aws >/dev/null 2>&1; then
        log_warning "AWS CLI not installed. Attempting to install..."
        
        # Try to install AWS CLI
        if command -v apt-get >/dev/null 2>&1; then
            # Ubuntu/Debian
            log_info "Installing AWS CLI via apt..."
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install
            rm -rf aws awscliv2.zip
        elif command -v yum >/dev/null 2>&1; then
            # CentOS/RHEL
            log_info "Installing AWS CLI via yum..."
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install
            rm -rf aws awscliv2.zip
        elif command -v brew >/dev/null 2>&1; then
            # macOS
            log_info "Installing AWS CLI via brew..."
            brew install awscli
        elif command -v pip3 >/dev/null 2>&1; then
            # Fallback to pip
            log_info "Installing AWS CLI via pip..."
            pip3 install awscli --upgrade --user
            export PATH="$HOME/.local/bin:$PATH"
        else
            log_error "Cannot install AWS CLI automatically. Please install manually:"
            log_error "  Ubuntu/Debian: curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip && unzip awscliv2.zip && sudo ./aws/install"
            log_error "  macOS: brew install awscli"
            log_error "  Or visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
            return 0
        fi
        
        # Verify installation
        if ! command -v aws >/dev/null 2>&1; then
            log_error "AWS CLI installation failed. Cannot upload to S3."
            return 0
        fi
        
        log_success "AWS CLI installed successfully"
    fi
    
    # Extract date from timestamp (YYYYMMDD_HHMMSS -> YYYY-MM-DD)
    local backup_date=$(echo "$timestamp" | cut -d'_' -f1 | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3/')
    local s3_key="backups/$backup_date/backup_$timestamp.tar.gz"
    
    log_info "Uploading backup to S3: s3://${S3_BUCKET_NAME}/$s3_key"
    
    # Set AWS credentials from environment variables
    export AWS_ACCESS_KEY_ID="${S3_ACCESS_KEY_ID}"
    export AWS_SECRET_ACCESS_KEY="${S3_SECRET_ACCESS_KEY}"
    export AWS_DEFAULT_REGION="${S3_REGION}"
    
    if [ -n "${S3_ENDPOINT_URL}" ] && [ "${S3_ENDPOINT_URL}" != "https://s3.amazonaws.com" ]; then
        aws s3 cp "$backup_file" "s3://${S3_BUCKET_NAME}/$s3_key" \
            --region "${S3_REGION}" \
            --endpoint-url "${S3_ENDPOINT_URL}"
    else
        aws s3 cp "$backup_file" "s3://${S3_BUCKET_NAME}/$s3_key" \
            --region "${S3_REGION}"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "Backup uploaded to S3 successfully"
        # Keep local backup file for 30 days (redundancy and faster access)
    else
        log_error "Failed to upload backup to S3"
        return 0
    fi
}

# Upload single backup file to S3
upload_single_backup_to_s3() {
    local backup_file="$1"
    local timestamp="$2"
    local db_type="$3"
    
    if [ ! -f "$backup_file" ]; then
        log_error "Backup file not found: $backup_file"
        return 0
    fi
    
    if ! command -v aws >/dev/null 2>&1; then
        log_warning "AWS CLI not installed. Cannot upload to S3."
        return 0
    fi
    
    # Extract date from timestamp (YYYYMMDD_HHMMSS -> YYYY-MM-DD)
    local backup_date=$(echo "$timestamp" | cut -d'_' -f1 | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3/')
    local s3_key="backups/$backup_date/${db_type}_backup_$timestamp.sql"
    
    # Add .gz extension if compressed
    if [ "$BACKUP_COMPRESSION" = "true" ]; then
        s3_key="${s3_key}.gz"
    fi
    
    log_info "Uploading $db_type backup to S3: s3://${S3_BUCKET_NAME}/$s3_key"
    
    # Set AWS credentials from environment variables
    export AWS_ACCESS_KEY_ID="${S3_ACCESS_KEY_ID}"
    export AWS_SECRET_ACCESS_KEY="${S3_SECRET_ACCESS_KEY}"
    export AWS_DEFAULT_REGION="${S3_REGION}"
    
    if [ -n "${S3_ENDPOINT_URL}" ] && [ "${S3_ENDPOINT_URL}" != "https://s3.amazonaws.com" ]; then
        aws s3 cp "$backup_file" "s3://${S3_BUCKET_NAME}/$s3_key" \
            --region "${S3_REGION}" \
            --endpoint-url "${S3_ENDPOINT_URL}"
    else
        aws s3 cp "$backup_file" "s3://${S3_BUCKET_NAME}/$s3_key" \
            --region "${S3_REGION}"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "$db_type backup uploaded to S3 successfully"
    else
        log_error "Failed to upload $db_type backup to S3"
        return 0
    fi
}

# Cleanup old backups
cleanup_old_backups() {
    echo "🧹 Cleaning Up Old Backups"
    echo "=========================="
    echo ""
    
    if [ ! -d "$BACKUP_LOCAL_DIR" ]; then
        echo "❌ No backup directory found"
        return 0
    fi
    
    local retention_days=${BACKUP_RETENTION_DAYS:-30}
    log_info "Removing backups older than $retention_days days..."
    
    # Remove old date directories
    find "$BACKUP_LOCAL_DIR" -type d -name "*-*-*" -mtime +$retention_days -exec rm -rf {} \; 2>/dev/null || true
    
    # Remove old compressed backups
    find "$BACKUP_LOCAL_DIR" -name "backup_*.tar.gz" -mtime +$retention_days -delete 2>/dev/null || true
    
    # Count remaining backups
    local remaining=$(find "$BACKUP_LOCAL_DIR" -type f | wc -l)
    log_success "Cleanup completed. $remaining backup files remaining."
}

# Test backup system
test_backup_system() {
    echo "🧪 Testing Backup System"
    echo "========================"
    echo ""
    
    # Test MySQL backup
    if docker ps | grep -q mysql; then
        echo "✅ MySQL container is running"
        backup_mysql_only
    else
        echo "❌ MySQL container is not running"
    fi
    
    echo ""
    
    # Test PostgreSQL backup
    if docker ps | grep -q postgres; then
        echo "✅ PostgreSQL container is running"
        backup_postgres_only
    else
        echo "❌ PostgreSQL container is not running"
    fi
    
    echo ""
    
    # Test Redis backup
    if docker ps | grep -q redis; then
        echo "✅ Redis container is running"
        backup_redis_only
    else
        echo "❌ Redis container is not running"
    fi
    
    echo ""
    echo "🧪 Backup system test completed!"
}

# Show backup status
show_backup_status() {
    echo "📊 Backup Status & Information"
    echo "=============================="
    echo ""
    
    # Check backup directory
    if [ -d "$BACKUP_LOCAL_DIR" ]; then
        echo "📁 Backup Directory: $BACKUP_LOCAL_DIR"
        echo "📊 Total Size: $(du -sh "$BACKUP_LOCAL_DIR" | cut -f1)"
        echo "📄 Total Files: $(find "$BACKUP_LOCAL_DIR" -type f | wc -l)"
    else
        echo "❌ Backup directory not found: $BACKUP_LOCAL_DIR"
    fi
    
    echo ""
    echo "⏰ Automated Backup Status:"
    local cron_jobs=$(crontab -l 2>/dev/null | grep -c "backup.sh" 2>/dev/null || echo "0")
    cron_jobs=$(echo "$cron_jobs" | tr -d '\n')
    if [ "$cron_jobs" -gt 0 ]; then
        echo "  ✅ Automated backups enabled ($cron_jobs job(s))"
        echo "  📋 Cron jobs:"
        crontab -l 2>/dev/null | grep "backup.sh" | while read job; do
            echo "    $job"
        done
    else
        echo "  ❌ No automated backups configured"
    fi
    
    echo ""
    echo "☁️  S3 Backup Status:"
    if [ "$S3_BACKUP_ENABLED" = "true" ]; then
        echo "  ✅ S3 backup enabled"
        echo "  🪣 Bucket: $S3_BUCKET_NAME"
        echo "  🌍 Region: $S3_REGION"
        if [ -n "$S3_ENDPOINT_URL" ]; then
            echo "  🔗 Endpoint: $S3_ENDPOINT_URL"
        fi
    else
        echo "  ❌ S3 backup disabled"
    fi
    
    echo ""
    echo "📅 Retention Policy:"
    echo "  🗓️  Local backups: $BACKUP_RETENTION_DAYS days"
    echo "  📦 Compression: $BACKUP_COMPRESSION"
}

# Command line argument handler (only when script is executed directly)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ $# -gt 0 ]; then
        case "$1" in
            "backup_mysql_only")
                backup_mysql_only
                ;;
            "backup_postgres_only")
                backup_postgres_only
                ;;
            "backup_redis_only")
                backup_redis_only
                ;;
            "backup_clickhouse_only")
                backup_clickhouse_only
                ;;
            "backup_all_databases")
                backup_all_databases
                ;;
            "list_backups")
                list_backups
                ;;
            "test_backup_system")
                test_backup_system
                ;;
            "show_backup_status")
                show_backup_status
                ;;
            "cleanup_old_backups")
                cleanup_old_backups
                ;;
            *)
                echo "❌ Unknown command: $1"
                echo "Available commands:"
                echo "  backup_mysql_only - Backup MySQL only"
                echo "  backup_postgres_only - Backup PostgreSQL only"
                echo "  backup_redis_only - Backup Redis only"
                echo "  backup_clickhouse_only - Backup ClickHouse only"
                echo "  backup_all_databases - Backup all databases"
                echo "  list_backups - List all backups"
                echo "  test_backup_system - Test backup system"
                echo "  show_backup_status - Show backup status"
                echo "  cleanup_old_backups - Clean old backups"
                exit 1
                ;;
        esac
    fi
fi
