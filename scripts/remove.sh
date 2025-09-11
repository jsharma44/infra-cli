#!/bin/bash

# 🗑️ Remove & Cleanup Functions
# All removal and cleanup functionality
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
# REMOVAL CONFIGURATION
# =============================================================================

# Backup directory
BACKUP_LOCAL_DIR="${BACKUP_LOCAL_DIR:-./backups}"

# =============================================================================
# BACKUP CLEANUP FUNCTIONS
# =============================================================================

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

# Cleanup local backups only
cleanup_local_backups() {
    echo "🧹 Cleaning Up Local Backups"
    echo "============================"
    echo ""
    
    local retention_days=${BACKUP_RETENTION_DAYS:-30}
    log_info "Removing local backups older than $retention_days days..."
    
    if [ ! -d "$BACKUP_LOCAL_DIR" ]; then
        echo "❌ No backup directory found"
        return 0
    fi
    
    # Remove old date directories
    find "$BACKUP_LOCAL_DIR" -type d -name "*-*-*" -mtime +$retention_days -exec rm -rf {} \; 2>/dev/null || true
    
    # Remove old compressed backups
    find "$BACKUP_LOCAL_DIR" -name "backup_*.tar.gz" -mtime +$retention_days -delete 2>/dev/null || true
    
    # Count remaining backups
    local remaining=$(find "$BACKUP_LOCAL_DIR" -type f | wc -l)
    log_success "Local cleanup completed. $remaining backup files remaining."
}

# Cleanup S3 backups only
cleanup_s3_backups() {
    echo "☁️  Cleaning Up S3 Backups"
    echo "========================="
    echo ""
    
    if [ "$S3_BACKUP_ENABLED" != "true" ]; then
        echo "❌ S3 backup not enabled"
        return 0
    fi
    
    if ! command -v aws >/dev/null 2>&1; then
        echo "❌ AWS CLI not installed"
        return 0
    fi
    
    local retention_days=${BACKUP_RETENTION_DAYS:-30}
    log_info "Removing S3 backups older than $retention_days days..."
    
    # Calculate cutoff date
    local cutoff_date=$(date -d "$retention_days days ago" +%Y-%m-%d 2>/dev/null || date -v-${retention_days}d +%Y-%m-%d 2>/dev/null)
    
    # Set AWS credentials from environment variables
    export AWS_ACCESS_KEY_ID="${S3_ACCESS_KEY_ID}"
    export AWS_SECRET_ACCESS_KEY="${S3_SECRET_ACCESS_KEY}"
    export AWS_DEFAULT_REGION="${S3_REGION}"
    
    # List all date directories in S3
    local s3_cmd="aws s3 ls s3://${S3_BUCKET_NAME}/backups/ --region ${S3_REGION}"
    if [ -n "${S3_ENDPOINT_URL}" ] && [ "${S3_ENDPOINT_URL}" != "https://s3.amazonaws.com" ]; then
        s3_cmd="$s3_cmd --endpoint-url ${S3_ENDPOINT_URL}"
    fi
    
    # Get date directories and check if they're older than retention period
    $s3_cmd | grep "PRE" | while read line; do
        local date_dir=$(echo "$line" | awk '{print $2}' | sed 's|/||')
        
        # Compare dates (simple string comparison works for YYYY-MM-DD format)
        if [ "$date_dir" \< "$cutoff_date" ]; then
            log_info "Removing old S3 directory: $date_dir"
            
            # Remove the entire date directory
            local remove_cmd="aws s3 rm s3://${S3_BUCKET_NAME}/backups/$date_dir/ --recursive --region ${S3_REGION}"
            if [ -n "${S3_ENDPOINT_URL}" ] && [ "${S3_ENDPOINT_URL}" != "https://s3.amazonaws.com" ]; then
                remove_cmd="$remove_cmd --endpoint-url ${S3_ENDPOINT_URL}"
            fi
            
            $remove_cmd
        fi
    done
    
    log_success "S3 cleanup completed."
}

# Cleanup both local and S3 backups
cleanup_both_backups() {
    echo "🔄 Cleaning Up Local and S3 Backups"
    echo "==================================="
    echo ""
    
    cleanup_local_backups
    echo ""
    cleanup_s3_backups
}

# Aggressive S3 cleanup (7 days)
cleanup_s3_aggressive() {
    echo "⚡ Aggressive S3 Cleanup (7 days)"
    echo "================================="
    echo ""
    
    if [ "$S3_BACKUP_ENABLED" != "true" ]; then
        echo "❌ S3 backup not enabled"
        return 0
    fi
    
    if ! command -v aws >/dev/null 2>&1; then
        echo "❌ AWS CLI not installed"
        return 0
    fi
    
    local retention_days=7
    log_info "Removing S3 backups older than $retention_days days (aggressive cleanup)..."
    
    # Calculate cutoff date
    local cutoff_date=$(date -d "$retention_days days ago" +%Y-%m-%d 2>/dev/null || date -v-${retention_days}d +%Y-%m-%d 2>/dev/null)
    
    # Set AWS credentials from environment variables
    export AWS_ACCESS_KEY_ID="${S3_ACCESS_KEY_ID}"
    export AWS_SECRET_ACCESS_KEY="${S3_SECRET_ACCESS_KEY}"
    export AWS_DEFAULT_REGION="${S3_REGION}"
    
    # List all date directories in S3
    local s3_cmd="aws s3 ls s3://${S3_BUCKET_NAME}/backups/ --region ${S3_REGION}"
    if [ -n "${S3_ENDPOINT_URL}" ] && [ "${S3_ENDPOINT_URL}" != "https://s3.amazonaws.com" ]; then
        s3_cmd="$s3_cmd --endpoint-url ${S3_ENDPOINT_URL}"
    fi
    
    # Get date directories and check if they're older than retention period
    $s3_cmd | grep "PRE" | while read line; do
        local date_dir=$(echo "$line" | awk '{print $2}' | sed 's|/||')
        
        # Compare dates (simple string comparison works for YYYY-MM-DD format)
        if [ "$date_dir" \< "$cutoff_date" ]; then
            log_info "Removing old S3 directory: $date_dir"
            
            # Remove the entire date directory
            local remove_cmd="aws s3 rm s3://${S3_BUCKET_NAME}/backups/$date_dir/ --recursive --region ${S3_REGION}"
            if [ -n "${S3_ENDPOINT_URL}" ] && [ "${S3_ENDPOINT_URL}" != "https://s3.amazonaws.com" ]; then
                remove_cmd="$remove_cmd --endpoint-url ${S3_ENDPOINT_URL}"
            fi
            
            $remove_cmd
        fi
    done
    
    log_success "Aggressive S3 cleanup completed."
}

# Aggressive cleanup both local and S3 (7 days)
cleanup_both_aggressive() {
    echo "⚡ Aggressive Cleanup (7 days) - Local and S3"
    echo "============================================="
    echo ""
    
    # Set retention to 7 days temporarily
    local original_retention=$BACKUP_RETENTION_DAYS
    export BACKUP_RETENTION_DAYS=7
    
    cleanup_local_backups
    echo ""
    cleanup_s3_aggressive
    
    # Restore original retention
    export BACKUP_RETENTION_DAYS=$original_retention
}

# =============================================================================
# CRON REMOVAL FUNCTIONS
# =============================================================================

# Remove automated backups (cron)
remove_automated_backups() {
    echo "🗑️  Removing Automated Backups"
    echo "=============================="
    echo ""
    
    # Get current crontab
    local current_crontab=$(crontab -l 2>/dev/null || echo "")
    
    if [ -z "$current_crontab" ]; then
        echo "❌ No crontab found for user $USER"
        return 0
    fi
    
    # Check if backup jobs exist
    if echo "$current_crontab" | grep -q "backup.sh"; then
        echo "📋 Found backup cron jobs:"
        echo "$current_crontab" | grep "backup.sh"
        echo ""
        
        read -p "Are you sure you want to remove all backup cron jobs? (y/N): " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            # Remove backup jobs
            echo "$current_crontab" | grep -v "backup.sh" | crontab -
            
            if [ $? -eq 0 ]; then
                log_success "Automated backup cron jobs removed successfully!"
            else
                log_error "Failed to remove cron jobs"
                return 0
            fi
        else
            echo "❌ Operation cancelled"
        fi
    else
        echo "❌ No backup cron jobs found"
    fi
}

# Remove all cron jobs
remove_all_cron_jobs() {
    echo "🗑️  Remove All Cron Jobs"
    echo "========================"
    echo ""
    
    local cron_jobs=$(crontab -l 2>/dev/null)
    
    if [ -z "$cron_jobs" ]; then
        echo "❌ No cron jobs found"
        return 0
    fi
    
    echo "⚠️  WARNING: This will remove ALL cron jobs for user $USER"
    echo ""
    echo "📋 Current cron jobs:"
    echo "$cron_jobs" | while IFS= read -r job; do
        if [ -n "$job" ] && [[ ! "$job" =~ ^# ]]; then
            echo "  📄 $job"
        fi
    done
    echo ""
    
    read -p "Are you sure you want to remove ALL cron jobs? (y/N): " confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        # Remove all cron jobs
        crontab -r
        
        if [ $? -eq 0 ]; then
            log_success "All cron jobs removed successfully!"
        else
            log_error "Failed to remove cron jobs"
            return 0
        fi
    else
        echo "❌ Operation cancelled"
    fi
}

# Remove backup cron jobs only
remove_backup_cron_jobs() {
    echo "🧹 Remove Backup Cron Jobs Only"
    echo "==============================="
    echo ""
    
    local cron_jobs=$(crontab -l 2>/dev/null)
    
    if [ -z "$cron_jobs" ]; then
        echo "❌ No cron jobs found"
        return 0
    fi
    
    # Check if backup jobs exist
    if echo "$cron_jobs" | grep -q -i "backup\|cleanup"; then
        echo "📋 Found backup-related cron jobs:"
        echo "$cron_jobs" | grep -i "backup\|cleanup" | while IFS= read -r job; do
            echo "  📄 $job"
        done
        echo ""
        
        read -p "Are you sure you want to remove backup cron jobs? (y/N): " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            # Remove backup jobs
            echo "$cron_jobs" | grep -v -i "backup\|cleanup" | crontab -
            
            if [ $? -eq 0 ]; then
                log_success "Backup cron jobs removed successfully!"
                echo ""
                echo "📋 Remaining cron jobs:"
                crontab -l 2>/dev/null | while IFS= read -r job; do
                    if [ -n "$job" ] && [[ ! "$job" =~ ^# ]]; then
                        echo "  📄 $job"
                    fi
                done
            else
                log_error "Failed to remove backup cron jobs"
                return 0
            fi
        else
            echo "❌ Operation cancelled"
        fi
    else
        echo "❌ No backup-related cron jobs found"
    fi
}

# =============================================================================
# LOG REMOVAL FUNCTIONS
# =============================================================================

# Remove cron logs
remove_cron_logs() {
    echo "🗑️  Remove Cron Logs"
    echo "===================="
    echo ""
    
    local logs_dir="$SCRIPT_DIR/logs"
    
    if [ ! -d "$logs_dir" ]; then
        echo "❌ No logs directory found: $logs_dir"
        return 0
    fi
    
    # Find cron log files (backup, cleanup, restore, etc.)
    local cron_logs=($(find "$logs_dir" -name "*_automated_*.log" -o -name "*_cleanup_*.log" -o -name "*_restore_*.log" -o -name "*_backup_*.log" -o -name "*cron*.log" -type f | sort))
    
    if [ ${#cron_logs[@]} -eq 0 ]; then
        echo "❌ No cron log files found"
        return 0
    fi
    
    echo "📋 Found cron log files:"
    local file_number=1
    for log_file in "${cron_logs[@]}"; do
        local filename=$(basename "$log_file")
        local file_size=$(du -h "$log_file" | cut -f1)
        local file_date=$(stat -c %y "$log_file" 2>/dev/null || stat -f %Sm "$log_file" 2>/dev/null)
        echo "$file_number) $filename ($file_size) - $file_date"
        ((file_number++))
    done
    
    echo ""
    echo "🗑️  Removal Options:"
    echo "1) Remove specific log files"
    echo "2) Remove all cron log files"
    echo "3) Cancel"
    echo ""
    
    read -p "Choose option (1-3): " option_choice
    
    case $option_choice in
        1)
            echo ""
            read -p "Enter log file numbers to remove (comma-separated, e.g., 1,3): " file_choices
            
            # Parse comma-separated choices
            IFS=',' read -ra choices <<< "$file_choices"
            local removed_count=0
            
            for choice in "${choices[@]}"; do
                choice=$(echo "$choice" | tr -d ' ') # Remove spaces
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#cron_logs[@]} ]; then
                    local selected_log="${cron_logs[$((choice-1))]}"
                    echo "🗑️  Removing: $(basename "$selected_log")"
                    rm -f "$selected_log"
                    if [ $? -eq 0 ]; then
                        ((removed_count++))
                    fi
                else
                    echo "❌ Invalid choice: $choice"
                fi
            done
            
            if [ $removed_count -gt 0 ]; then
                log_success "Removed $removed_count cron log file(s)"
            fi
            ;;
        2)
            echo ""
            echo "⚠️  This will remove ALL cron log files!"
            read -p "Are you sure? (y/N): " confirm
            
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                local removed_count=0
                for log_file in "${cron_logs[@]}"; do
                    echo "🗑️  Removing: $(basename "$log_file")"
                    rm -f "$log_file"
                    if [ $? -eq 0 ]; then
                        ((removed_count++))
                    fi
                done
                
                if [ $removed_count -gt 0 ]; then
                    log_success "Removed all $removed_count cron log file(s)"
                fi
            else
                echo "❌ Operation cancelled"
            fi
            ;;
        3)
            echo "❌ Operation cancelled"
            ;;
        *)
            echo "❌ Invalid choice"
            ;;
    esac
}

# Clean old cron logs
clean_old_cron_logs() {
    echo "🧹 Clean Old Cron Logs"
    echo "======================"
    echo ""
    
    local logs_dir="$SCRIPT_DIR/logs"
    
    if [ ! -d "$logs_dir" ]; then
        echo "❌ No logs directory found: $logs_dir"
        return 0
    fi
    
    echo "📅 Cleanup Options:"
    echo "1) Remove logs older than 7 days"
    echo "2) Remove logs older than 30 days"
    echo "3) Remove logs older than 90 days"
    echo "4) Custom number of days"
    echo "5) Cancel"
    echo ""
    
    read -p "Choose option (1-5): " option_choice
    
    local retention_days=""
    case $option_choice in
        1) retention_days=7 ;;
        2) retention_days=30 ;;
        3) retention_days=90 ;;
        4)
            read -p "Enter number of days: " retention_days
            if ! [[ "$retention_days" =~ ^[0-9]+$ ]]; then
                echo "❌ Invalid number of days"
                return 0
            fi
            ;;
        5)
            echo "❌ Operation cancelled"
            return 0
            ;;
        *)
            echo "❌ Invalid choice"
            return 0
            ;;
    esac
    
    echo ""
    echo "🔍 Finding cron log files older than $retention_days days..."
    
    # Find old cron log files (backup, cleanup, restore, etc.)
    local old_logs=($(find "$logs_dir" -name "*_automated_*.log" -o -name "*_cleanup_*.log" -o -name "*_restore_*.log" -o -name "*_backup_*.log" -o -name "*cron*.log" -type f -mtime +$retention_days))
    
    if [ ${#old_logs[@]} -eq 0 ]; then
        echo "✅ No cron log files older than $retention_days days found"
        return 0
    fi
    
    echo "📋 Found ${#old_logs[@]} old cron log file(s):"
    for log_file in "${old_logs[@]}"; do
        local filename=$(basename "$log_file")
        local file_size=$(du -h "$log_file" | cut -f1)
        local file_date=$(stat -c %y "$log_file" 2>/dev/null || stat -f %Sm "$log_file" 2>/dev/null)
        echo "  📄 $filename ($file_size) - $file_date"
    done
    
    echo ""
    read -p "Remove these old cron log files? (y/N): " confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        local removed_count=0
        for log_file in "${old_logs[@]}"; do
            echo "🗑️  Removing: $(basename "$log_file")"
            rm -f "$log_file"
            if [ $? -eq 0 ]; then
                ((removed_count++))
            fi
        done
        
        if [ $removed_count -gt 0 ]; then
            log_success "Removed $removed_count old cron log file(s)"
        fi
    else
        echo "❌ Operation cancelled"
    fi
}

# Command line argument handler
if [ $# -gt 0 ]; then
    case "$1" in
        "cleanup_old_backups")
            cleanup_old_backups
            ;;
        "cleanup_local")
            cleanup_local_backups
            ;;
        "cleanup_s3")
            cleanup_s3_backups
            ;;
        "cleanup_both")
            cleanup_both_backups
            ;;
        "cleanup_s3_aggressive")
            cleanup_s3_aggressive
            ;;
        "cleanup_both_aggressive")
            cleanup_both_aggressive
            ;;
        "remove_automated_backups")
            remove_automated_backups
            ;;
        "remove_all_cron")
            remove_all_cron_jobs
            ;;
        "remove_backup_cron")
            remove_backup_cron_jobs
            ;;
        "remove_cron_logs")
            remove_cron_logs
            ;;
        "clean_old_cron_logs")
            clean_old_cron_logs
            ;;
        *)
            echo "❌ Unknown command: $1"
            echo "Available commands:"
            echo "  cleanup_old_backups - Clean old backups (30 days)"
            echo "  cleanup_local - Clean local backups only"
            echo "  cleanup_s3 - Clean S3 backups only"
            echo "  cleanup_both - Clean both local and S3 backups"
            echo "  cleanup_s3_aggressive - Aggressive S3 cleanup (7 days)"
            echo "  cleanup_both_aggressive - Aggressive cleanup both (7 days)"
            echo "  remove_automated_backups - Remove backup cron jobs"
            echo "  remove_all_cron - Remove all cron jobs"
            echo "  remove_backup_cron - Remove backup cron jobs only"
            echo "  remove_cron_logs - Remove cron log files"
            echo "  clean_old_cron_logs - Clean old cron log files"
            exit 1
            ;;
    esac
fi
