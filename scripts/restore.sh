#!/bin/bash

# 🔄 Restore Functions
# Database restore functionality
# Separated from backup.sh for better organization

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
# RESTORE CONFIGURATION
# =============================================================================

# Backup directory
BACKUP_LOCAL_DIR="${BACKUP_LOCAL_DIR:-./backups}"

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# Format file size for display (cross-platform)
format_file_size() {
    local size="$1"
    if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec "$size"
    else
        # Fallback for macOS and other systems without numfmt
        if [ "$size" -gt 1073741824 ]; then
            echo "$(($size / 1073741824))GB"
        elif [ "$size" -gt 1048576 ]; then
            echo "$(($size / 1048576))MB"
        elif [ "$size" -gt 1024 ]; then
            echo "$(($size / 1024))KB"
        else
            echo "${size}B"
        fi
    fi
}

# =============================================================================
# RESTORE FUNCTIONS
# =============================================================================

# Main restore database function
restore_database() {
    echo "🔄 Database Restore"
    echo "=================="
    echo ""
    
    # Check if backup directory exists
    if [ ! -d "$BACKUP_LOCAL_DIR" ]; then
        echo "❌ Backup directory not found: $BACKUP_LOCAL_DIR"
        return 0
    fi
    
    # List available databases
    echo "Available databases: mysql, postgres, redis, clickhouse"
    echo ""
    
    # Ask for database name
    read -p "Enter database name: " db_name
    
    if [ -z "$db_name" ]; then
        echo "❌ Database name cannot be empty"
        return 0
    fi
    
    # List available backups
    echo ""
    echo "📋 Available backups for $db_name:"
    list_backups_for_database "$db_name"
    echo ""
    
    read -p "Enter backup file name: " backup_file
    
    if [ -z "$backup_file" ]; then
        echo "❌ Backup file name cannot be empty"
        return 0
    fi
    
    # Check if backup file exists locally or in S3
    local full_path=""
    if [ -f "$BACKUP_LOCAL_DIR/$backup_file" ]; then
        full_path="$BACKUP_LOCAL_DIR/$backup_file"
    elif [ -f "$backup_file" ]; then
        full_path="$backup_file"
    else
        # Search for the file recursively in backup directory
        local found_file=$(find "$BACKUP_LOCAL_DIR" -name "$backup_file" -type f 2>/dev/null | head -1)
        if [ -n "$found_file" ]; then
            full_path="$found_file"
        elif [ "$S3_BACKUP_ENABLED" = "true" ]; then
            # Try to download from S3
            echo "📥 Downloading backup from S3..."
            
            # Extract date from backup filename for S3 path
            local backup_date=""
            if [[ "$backup_file" =~ backup_([0-9]{8})_ ]]; then
                local date_part="${BASH_REMATCH[1]}"
                backup_date=$(echo "$date_part" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3/')
            fi
            
            local s3_path="s3://${S3_BUCKET_NAME}/backups/$backup_date/$backup_file"
            local local_path="$BACKUP_LOCAL_DIR/$backup_file"
            
            # Set AWS credentials from environment variables
            export AWS_ACCESS_KEY_ID="${S3_ACCESS_KEY_ID}"
            export AWS_SECRET_ACCESS_KEY="${S3_SECRET_ACCESS_KEY}"
            export AWS_DEFAULT_REGION="${S3_REGION}"
            
            if [ -n "${S3_ENDPOINT_URL}" ] && [ "${S3_ENDPOINT_URL}" != "https://s3.amazonaws.com" ]; then
                aws s3 cp "$s3_path" "$local_path" \
                    --region "${S3_REGION}" \
                    --endpoint-url "${S3_ENDPOINT_URL}"
            else
                aws s3 cp "$s3_path" "$local_path" \
                    --region "${S3_REGION}"
            fi
            
            if [ $? -eq 0 ] && [ -f "$local_path" ]; then
                full_path="$local_path"
                log_success "Backup downloaded from S3 successfully"
            else
                echo "❌ Failed to download backup from S3: $s3_path"
                return 0
            fi
        else
            echo "❌ Backup file not found: $backup_file"
            return 0
        fi
    fi
    
    # Determine database type from backup filename
    local db_name=""
    if [[ "$backup_file" == *"mysql"* ]]; then
        db_name="mysql"
    elif [[ "$backup_file" == *"postgres"* ]]; then
        db_name="postgres"
    elif [[ "$backup_file" == *"redis"* ]]; then
        db_name="redis"
    elif [[ "$backup_file" == *"clickhouse"* ]]; then
        db_name="clickhouse"
    else
        echo "❌ Cannot determine database type from filename: $backup_file"
        return 0
    fi
    
    echo ""
    echo "⚠️  This will restore $db_name database from $backup_file"
    echo "⚠️  This will OVERWRITE existing data!"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "❌ Restore cancelled"
        return 0
    fi
    
    # Check if it's a tar.gz file (full backup archive)
    if [[ "$backup_file" == *.tar.gz ]]; then
        echo "📦 Detected full backup archive. Extracting specific database backup..."
        local temp_dir=$(mktemp -d)
        tar -xzf "$full_path" -C "$temp_dir"
        
        # Find the specific database backup file
        local db_backup_file=$(find "$temp_dir" -name "*${db_name}_backup_*" | head -1)
        
        if [ -z "$db_backup_file" ]; then
            echo "❌ No $db_name backup found in archive"
            rm -rf "$temp_dir"
            return 0
        fi
        
        echo "📄 Found database backup: $(basename "$db_backup_file")"
        
        # Restore using the extracted file
        case $db_name in
            "mysql")
                restore_mysql "$db_backup_file"
                ;;
            "postgres")
                restore_postgres "$db_backup_file"
                ;;
            "redis")
                restore_redis "$db_backup_file"
                ;;
            "clickhouse")
                restore_clickhouse "$db_backup_file"
                ;;
            *)
                echo "❌ Unsupported database: $db_name"
                rm -rf "$temp_dir"
                return 0
                ;;
        esac
        
        # Cleanup temp directory
        rm -rf "$temp_dir"
    else
        # Restore based on database type (single database backup)
        case $db_name in
            "mysql")
                restore_mysql "$full_path"
                ;;
            "postgres")
                restore_postgres "$full_path"
                ;;
            "redis")
                restore_redis "$full_path"
                ;;
            "clickhouse")
                restore_clickhouse "$full_path"
                ;;
            *)
                echo "❌ Unknown database: $db_name"
                return 0
                ;;
        esac
    fi
}

# Restore MySQL database
restore_mysql() {
    local backup_file="$1"
    
    echo "🔄 Restoring MySQL database..."
    
    # Check if MySQL container is running
    if ! docker ps | grep -q mysql; then
        echo "❌ MySQL container is not running"
        return 0
    fi
    
    # Check if backup file exists
    if [ ! -f "$backup_file" ]; then
        echo "❌ Backup file not found: $backup_file"
        return 0
    fi
    
    # Restore database
    log_info "Restoring MySQL database from $backup_file..."
    
    if [[ "$backup_file" == *.gz ]]; then
        gunzip -c "$backup_file" | docker exec -i mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD:-password}"
    else
        docker exec -i mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD:-password}" < "$backup_file"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "MySQL database restored successfully"
    else
        log_error "MySQL database restore failed"
        return 0
    fi
}

# Restore PostgreSQL database
restore_postgres() {
    local backup_file="$1"
    
    echo "🔄 Restoring PostgreSQL database..."
    
    # Check if PostgreSQL container is running
    if ! docker ps | grep -q postgres; then
        echo "❌ PostgreSQL container is not running"
        return 0
    fi
    
    # Check if backup file exists
    if [ ! -f "$backup_file" ]; then
        echo "❌ Backup file not found: $backup_file"
        return 0
    fi
    
    # Restore database
    log_info "Restoring PostgreSQL database from $backup_file..."
    
    if [[ "$backup_file" == *.gz ]]; then
        gunzip -c "$backup_file" | PGPASSWORD="${POSTGRES_PASSWORD}" docker exec -i postgres psql -U "${POSTGRES_USER}"
    else
        PGPASSWORD="${POSTGRES_PASSWORD}" docker exec -i postgres psql -U "${POSTGRES_USER}" < "$backup_file"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "PostgreSQL database restored successfully"
    else
        log_error "PostgreSQL database restore failed"
        return 0
    fi
}

# Restore Redis database
restore_redis() {
    local backup_file="$1"
    
    echo "🔄 Restoring Redis database..."
    
    # Check if Redis container is running
    if ! docker ps | grep -q redis; then
        echo "❌ Redis container is not running"
        return 0
    fi
    
    # Check if backup file exists
    if [ ! -f "$backup_file" ]; then
        echo "❌ Backup file not found: $backup_file"
        return 0
    fi
    
    # Stop Redis
    docker stop redis
    
    # Copy backup file to Redis container
    docker cp "$backup_file" redis:/data/dump.rdb
    
    # Start Redis
    docker start redis
    
    if [ $? -eq 0 ]; then
        log_success "Redis database restored successfully"
    else
        log_error "Redis database restore failed"
        return 0
    fi
}

# Restore ClickHouse database
restore_clickhouse() {
    local backup_file="$1"
    
    echo "🔄 Restoring ClickHouse database..."
    
    # Check if ClickHouse container is running
    if ! docker ps | grep -q clickhouse; then
        echo "❌ ClickHouse container is not running"
        return 0
    fi
    
    # Check if backup file exists
    if [ ! -f "$backup_file" ]; then
        echo "❌ Backup file not found: $backup_file"
        return 0
    fi
    
    # Restore database
    log_info "Restoring ClickHouse database from $backup_file..."
    
    if [[ "$backup_file" == *.gz ]]; then
        gunzip -c "$backup_file" | docker exec -i clickhouse clickhouse-client
    else
        docker exec -i clickhouse clickhouse-client < "$backup_file"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "ClickHouse database restored successfully"
    else
        log_error "ClickHouse database restore failed"
        return 0
    fi
}

# List backups for specific database
list_backups_for_database() {
    local db_name="$1"
    
    # List local backups
    if [ -d "$BACKUP_LOCAL_DIR" ]; then
        find "$BACKUP_LOCAL_DIR" -name "*${db_name}_backup_*" -type f | sort -r | while read backup_file; do
            local filename=$(basename "$backup_file")
            local size=$(du -h "$backup_file" | cut -f1)
            local date=$(stat -c %y "$backup_file" 2>/dev/null || stat -f %Sm "$backup_file" 2>/dev/null)
            echo "  📄 $filename ($size) - $date [LOCAL]"
        done
    fi
    
    # List S3 backups if enabled
    if [ "$S3_BACKUP_ENABLED" = "true" ]; then
        echo "  ☁️  S3 Backups:"
        
        # Set AWS credentials from environment variables
        export AWS_ACCESS_KEY_ID="${S3_ACCESS_KEY_ID}"
        export AWS_SECRET_ACCESS_KEY="${S3_SECRET_ACCESS_KEY}"
        export AWS_DEFAULT_REGION="${S3_REGION}"
        
        if [ -n "${S3_ENDPOINT_URL}" ] && [ "${S3_ENDPOINT_URL}" != "https://s3.amazonaws.com" ]; then
            # List all date directories and search for database backups
            aws s3 ls "s3://${S3_BUCKET_NAME}/backups/" --region "${S3_REGION}" --endpoint-url "${S3_ENDPOINT_URL}" | grep "PRE" | while read line; do
                local date_dir=$(echo "$line" | awk '{print $2}' | sed 's|/||')
                aws s3 ls "s3://${S3_BUCKET_NAME}/backups/$date_dir/" --region "${S3_REGION}" --endpoint-url "${S3_ENDPOINT_URL}" | grep "${db_name}_backup_" | while read backup_line; do
                    local date=$(echo "$backup_line" | awk '{print $1" "$2}')
                    local size=$(echo "$backup_line" | awk '{print $3}')
                    local filename=$(echo "$backup_line" | awk '{print $4}')
                    echo "  📄 $filename ($(format_file_size $size)) - $date [S3]"
                done
            done
        else
            # List all date directories and search for database backups
            aws s3 ls "s3://${S3_BUCKET_NAME}/backups/" --region "${S3_REGION}" | grep "PRE" | while read line; do
                local date_dir=$(echo "$line" | awk '{print $2}' | sed 's|/||')
                aws s3 ls "s3://${S3_BUCKET_NAME}/backups/$date_dir/" --region "${S3_REGION}" | grep "${db_name}_backup_" | while read backup_line; do
                    local date=$(echo "$backup_line" | awk '{print $1" "$2}')
                    local size=$(echo "$backup_line" | awk '{print $3}')
                    local filename=$(echo "$backup_line" | awk '{print $4}')
                    echo "  📄 $filename ($(format_file_size $size)) - $date [S3]"
                done
            done
        fi
    fi
}

# Command line argument handler (only when script is executed directly)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ $# -gt 0 ]; then
        case "$1" in
            "restore_database")
                restore_database
                ;;
            "restore_mysql")
                restore_mysql "$2"
                ;;
            "restore_postgres")
                restore_postgres "$2"
                ;;
            "restore_redis")
                restore_redis "$2"
                ;;
            "restore_clickhouse")
                restore_clickhouse "$2"
                ;;
            "list_backups_for_database")
                list_backups_for_database "$2"
                ;;
            *)
                echo "❌ Unknown command: $1"
                echo "Available commands:"
                echo "  restore_database - Interactive database restore"
                echo "  restore_mysql <file> - Restore MySQL from file"
                echo "  restore_postgres <file> - Restore PostgreSQL from file"
                echo "  restore_redis <file> - Restore Redis from file"
                echo "  restore_clickhouse <file> - Restore ClickHouse from file"
                echo "  list_backups_for_database <db> - List backups for database"
                exit 1
                ;;
        esac
    fi
fi
