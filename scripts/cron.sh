#!/bin/bash

# ⏰ Cron Management Functions
# All cron job management functionality
# Separated from backup.sh for better organization

# Load environment variables
# SCRIPT_DIR should already be set by the main infra.sh script
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

# Load utility functions for logging
if [ -f "$SCRIPT_DIR/scripts/core.sh" ]; then
    source "$SCRIPT_DIR/scripts/core.sh"
fi

# =============================================================================
# CRON MANAGEMENT FUNCTIONS
# =============================================================================

# List all cron jobs
list_all_cron_jobs() {
    echo "📋 All Cron Jobs"
    echo "==============="
    echo ""
    
    local cron_jobs=$(crontab -l 2>/dev/null)
    
    if [ -z "$cron_jobs" ]; then
        echo "❌ No cron jobs found for user $USER"
        return 0
    fi
    
    echo "👤 User: $USER"
    echo "📅 Total jobs: $(echo "$cron_jobs" | grep -v '^#' | wc -l)"
    echo ""
    
    local job_number=1
    echo "$cron_jobs" | while IFS= read -r job; do
        if [ -n "$job" ] && [[ ! "$job" =~ ^# ]]; then
            # Extract description from job
            local description=""
            if echo "$job" | grep -q "backup.sh cleanup_both"; then
                description="🔄 Cleanup both local and S3 backups"
            elif echo "$job" | grep -q "backup.sh cleanup_local"; then
                description="🏠 Cleanup local backups only"
            elif echo "$job" | grep -q "backup.sh cleanup_s3"; then
                description="☁️  Cleanup S3 backups only"
            elif echo "$job" | grep -q "backup.sh cleanup_s3_aggressive"; then
                description="⚡ Aggressive S3 cleanup (7 days)"
            elif echo "$job" | grep -q "backup.sh cleanup_both_aggressive"; then
                description="⚡ Aggressive cleanup both (7 days)"
            elif echo "$job" | grep -q "backup.sh >> logs/backup_automated"; then
                description="📊 Automated database backup"
            elif echo "$job" | grep -q "backup.sh >> logs/backup_cron"; then
                description="📊 Database backup (legacy)"
            elif echo "$job" | grep -q "backup.sh"; then
                description="📊 Database backup"
            elif echo "$job" | grep -q "restore.sh"; then
                description="🔄 Database restore"
            elif echo "$job" | grep -q "remove.sh"; then
                description="🗑️  Cleanup operations"
            elif echo "$job" | grep -q "cron.sh"; then
                description="⏰ Cron management"
            elif echo "$job" | grep -q "logs.sh"; then
                description="📄 Log management"
            else
                description="🔧 Custom job"
            fi
            
            # Extract schedule and log file
            local schedule=$(echo "$job" | awk '{print $1" "$2" "$3" "$4" "$5}')
            local log_file=$(echo "$job" | grep -o 'logs/[^[:space:]]*' | head -1)
            
            echo "$job_number) $description"
            echo "   ⏰ Schedule: $schedule"
            if [ -n "$log_file" ]; then
                echo "   📄 Log: $log_file"
            fi
            echo ""
            ((job_number++))
        fi
    done
}

# Save cron jobs to file
save_cron_jobs() {
    echo "💾 Save Cron Jobs to File"
    echo "========================="
    echo ""
    
    local backup_dir="$SCRIPT_DIR/cron"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$backup_dir/crontab_$timestamp.txt"
    
    # Create backup directory if it doesn't exist
    mkdir -p "$backup_dir"
    
    # Get current crontab
    local cron_jobs=$(crontab -l 2>/dev/null)
    
    if [ -z "$cron_jobs" ]; then
        echo "❌ No cron jobs found to save"
        return 0
    fi
    
    # Save to file
    echo "$cron_jobs" > "$backup_file"
    
    if [ $? -eq 0 ]; then
        log_success "Cron jobs saved to: $backup_file"
        echo ""
        echo "📁 Backup directory: $backup_dir"
        echo "📄 File: $(basename "$backup_file")"
        echo "📊 Size: $(du -h "$backup_file" | cut -f1)"
        echo ""
        echo "🔄 To restore: ./infra.sh 36"
    else
        log_error "Failed to save cron jobs"
        return 0
    fi
}

# Restore cron jobs from file
restore_cron_jobs() {
    echo "📥 Restore Cron Jobs from File"
    echo "=============================="
    echo ""
    
    local backup_dir="$SCRIPT_DIR/cron"
    
    if [ ! -d "$backup_dir" ]; then
        echo "❌ No cron backup directory found: $backup_dir"
        return 0
    fi
    
    # List available backup files
    echo "📋 Available cron backups:"
    local backup_files=($(find "$backup_dir" -name "crontab_*.txt" -type f | sort -r))
    
    if [ ${#backup_files[@]} -eq 0 ]; then
        echo "❌ No cron backup files found"
        return 0
    fi
    
    local file_number=1
    for file in "${backup_files[@]}"; do
        local filename=$(basename "$file")
        local file_date=$(echo "$filename" | sed 's/crontab_\([0-9]\{8\}\)_\([0-9]\{6\}\)\.txt/\1 \2/' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
        local file_size=$(du -h "$file" | cut -f1)
        echo "$file_number) $filename ($file_size) - $file_date"
        ((file_number++))
    done
    
    echo ""
    read -p "Enter backup file number to restore (1-${#backup_files[@]}): " choice
    
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#backup_files[@]} ]; then
        echo "❌ Invalid choice"
        return 0
    fi
    
    local selected_file="${backup_files[$((choice-1))]}"
    
    echo ""
    echo "⚠️  This will REPLACE your current cron jobs!"
    echo "📄 Restoring from: $(basename "$selected_file")"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        # Restore crontab
        crontab "$selected_file"
        
        if [ $? -eq 0 ]; then
            log_success "Cron jobs restored successfully!"
            echo ""
            echo "📋 Current cron jobs:"
            crontab -l 2>/dev/null | while IFS= read -r job; do
                if [ -n "$job" ] && [[ ! "$job" =~ ^# ]]; then
                    echo "  📄 $job"
                fi
            done
        else
            log_error "Failed to restore cron jobs"
            return 0
        fi
    else
        echo "❌ Operation cancelled"
    fi
}

# Edit cron jobs manually
edit_cron_jobs_manually() {
    echo "🔧 Edit Cron Jobs Manually"
    echo "=========================="
    echo ""
    
    echo "📋 Current cron jobs:"
    crontab -l 2>/dev/null | while IFS= read -r job; do
        if [ -n "$job" ] && [[ ! "$job" =~ ^# ]]; then
            echo "  📄 $job"
        fi
    done
    echo ""
    
    echo "⚠️  This will open the default editor to modify cron jobs"
    echo "💡 Make sure to save and exit the editor properly"
    echo ""
    read -p "Continue with manual edit? (y/N): " confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        # Open crontab for editing
        crontab -e
        
        if [ $? -eq 0 ]; then
            log_success "Cron jobs edited successfully!"
            echo ""
            echo "📋 Updated cron jobs:"
            crontab -l 2>/dev/null | while IFS= read -r job; do
                if [ -n "$job" ] && [[ ! "$job" =~ ^# ]]; then
                    echo "  📄 $job"
                fi
            done
        else
            log_error "Failed to edit cron jobs"
            return 0
        fi
    else
        echo "❌ Operation cancelled"
    fi
}

# =============================================================================
# BACKUP CRON SETUP FUNCTIONS
# =============================================================================

# Setup automated backups (cron)
setup_automated_backups() {
    echo "⏰ Setting Up Automated Backups"
    echo "==============================="
    echo ""
    
    # Check if backup system is set up
    if [ ! -f "$SCRIPT_DIR/scripts/backup.sh" ]; then
        echo "❌ Backup system not found. Please run backup setup first."
        return 0
    fi
    
    local script_dir="$SCRIPT_DIR"
    local backup_script="$script_dir/backup.sh"
    
    echo "Choose backup schedule:"
    echo "1) Daily at 2:00 AM"
    echo "2) Daily at 3:00 AM"
    echo "3) Twice daily (2:00 AM and 2:00 PM)"
    echo "4) Weekly (Sunday at 2:00 AM)"
    echo "5) Custom schedule"
    echo ""
    
    read -p "Choose schedule (1-5): " schedule_choice
    
    local cron_schedule=""
    case $schedule_choice in
        1) cron_schedule="0 2 * * *" ;;
        2) cron_schedule="0 3 * * *" ;;
        3) cron_schedule="0 2,14 * * *" ;;
        4) cron_schedule="0 2 * * 0" ;;
        5)
            echo "Enter custom cron schedule (e.g., '0 2 * * *' for daily at 2 AM):"
            read -p "Cron schedule: " cron_schedule
            ;;
        *)
            echo "❌ Invalid choice"
            return 0
            ;;
    esac
    
    # Create cron job with descriptive log name
    local log_file="logs/backup_automated_$(date +%Y%m%d).log"
    local cron_job="$cron_schedule $USER cd $script_dir && $backup_script >> $log_file 2>&1"
    
    # Add to crontab
    echo "📝 Adding cron job..."
    (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
    
    if [ $? -eq 0 ]; then
        log_success "Automated backup cron job added successfully!"
        echo ""
        echo "📋 Cron job details:"
        echo "   Schedule: $cron_schedule"
        echo "   Script: $backup_script"
        echo "   Log: $script_dir/$log_file"
        echo ""
        echo "🔍 To view cron jobs: crontab -l"
        echo "🗑️  To remove cron jobs: crontab -e"
    else
        log_error "Failed to add cron job"
        return 0
    fi
}

# Setup automated cleanup (cron)
setup_cleanup_cron() {
    echo "🧹 Setting Up Automated Cleanup"
    echo "==============================="
    echo ""
    
    # Check if backup system is set up
    if [ ! -f "$SCRIPT_DIR/scripts/backup.sh" ]; then
        echo "❌ Backup system not found. Please run backup setup first."
        return 0
    fi
    
    local script_dir="$SCRIPT_DIR"
    local cleanup_script="$script_dir/backup.sh"
    
    echo "📋 Cleanup Options:"
    echo "1) 🏠 Local cleanup only (30 days)"
    echo "2) ☁️  S3 cleanup only (30 days)"
    echo "3) 🔄 Both local and S3 cleanup (30 days)"
    echo "4) 🗑️  S3 cleanup only (7 days - aggressive)"
    echo "5) ⚡ Both local and S3 cleanup (7 days - aggressive)"
    echo ""
    
    read -p "Choose cleanup type (1-5): " cleanup_choice
    
    local cleanup_type=""
    case $cleanup_choice in
        1) cleanup_type="local" ;;
        2) cleanup_type="s3" ;;
        3) cleanup_type="both" ;;
        4) cleanup_type="s3_aggressive" ;;
        5) cleanup_type="both_aggressive" ;;
        *)
            echo "❌ Invalid choice"
            return 0
            ;;
    esac
    
    echo ""
    echo "📅 Schedule Options:"
    echo "1) Daily at 3 AM"
    echo "2) Daily at 4 AM"
    echo "3) Twice daily (3 AM & 3 PM)"
    echo "4) Weekly (Sunday 3 AM)"
    echo "5) Custom schedule"
    echo ""
    
    read -p "Choose schedule (1-5): " schedule_choice
    
    local cron_schedule=""
    case $schedule_choice in
        1) cron_schedule="0 3 * * *" ;;
        2) cron_schedule="0 4 * * *" ;;
        3) cron_schedule="0 3,15 * * *" ;;
        4) cron_schedule="0 3 * * 0" ;;
        5)
            echo "Enter custom cron schedule (e.g., '0 3 * * *' for daily at 3 AM):"
            read -p "Cron schedule: " cron_schedule
            ;;
        *)
            echo "❌ Invalid choice"
            return 0
            ;;
    esac
    
    # Create cleanup script command with descriptive log name
    local log_file="logs/cleanup_${cleanup_type}_$(date +%Y%m%d).log"
    local cleanup_cmd=""
    case $cleanup_type in
        "local")
            cleanup_cmd="cd $script_dir && $cleanup_script cleanup_local >> $log_file 2>&1"
            ;;
        "s3")
            cleanup_cmd="cd $script_dir && $cleanup_script cleanup_s3 >> $log_file 2>&1"
            ;;
        "both")
            cleanup_cmd="cd $script_dir && $cleanup_script cleanup_both >> $log_file 2>&1"
            ;;
        "s3_aggressive")
            cleanup_cmd="cd $script_dir && $cleanup_script cleanup_s3_aggressive >> $log_file 2>&1"
            ;;
        "both_aggressive")
            cleanup_cmd="cd $script_dir && $cleanup_script cleanup_both_aggressive >> $log_file 2>&1"
            ;;
    esac
    
    # Create cron job
    local cron_job="$cron_schedule $USER $cleanup_cmd"
    
    # Add to crontab
    echo "📝 Adding cleanup cron job..."
    (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
    
    if [ $? -eq 0 ]; then
        log_success "Automated cleanup cron job added successfully!"
        echo ""
        echo "📋 Cron job details:"
        echo "   Schedule: $cron_schedule"
        echo "   Type: $cleanup_type"
        echo "   Command: $cleanup_cmd"
        echo "   Log: $script_dir/$log_file"
        echo ""
        echo "🔍 To view cron jobs: crontab -l"
        echo "🗑️  To remove cron jobs: crontab -e"
    else
        log_error "Failed to add cleanup cron job"
        return 0
    fi
}

# Command line argument handler (only when script is executed directly)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ $# -gt 0 ]; then
        case "$1" in
            "list_cron")
                list_all_cron_jobs
                ;;
            "save_cron")
                save_cron_jobs
                ;;
            "restore_cron")
                restore_cron_jobs
                ;;
            "edit_cron")
                edit_cron_jobs_manually
                ;;
            "setup_automated_backups")
                setup_automated_backups
                ;;
            "setup_cleanup_cron")
                setup_cleanup_cron
                ;;
            *)
                echo "❌ Unknown command: $1"
                echo "Available commands:"
                echo "  list_cron - List all cron jobs"
                echo "  save_cron - Save cron jobs to file"
                echo "  restore_cron - Restore cron jobs from file"
                echo "  edit_cron - Edit cron jobs manually"
                echo "  setup_automated_backups - Setup automated backup cron"
                echo "  setup_cleanup_cron - Setup automated cleanup cron"
                exit 1
                ;;
        esac
    fi
fi
