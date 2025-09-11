#!/bin/bash

# 📄 Log Management Functions
# All log viewing and management functionality
# Separated for better organization

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
# LOG MANAGEMENT FUNCTIONS
# =============================================================================

# View cron logs
view_cron_logs() {
    echo "📄 View Cron Logs"
    echo "================="
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
    
    echo "📋 Available cron log files:"
    local file_number=1
    for log_file in "${cron_logs[@]}"; do
        local filename=$(basename "$log_file")
        local file_size=$(du -h "$log_file" | cut -f1)
        local file_date=$(stat -c %y "$log_file" 2>/dev/null || stat -f %Sm "$log_file" 2>/dev/null)
        echo "$file_number) $filename ($file_size) - $file_date"
        ((file_number++))
    done
    
    echo ""
    read -p "Enter log file number to view (1-${#cron_logs[@]}): " choice
    
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#cron_logs[@]} ]; then
        echo "❌ Invalid choice"
        return 0
    fi
    
    local selected_log="${cron_logs[$((choice-1))]}"
    
    echo ""
    echo "📄 Viewing: $(basename "$selected_log")"
    echo "=========================================="
    echo ""
    
    # Show last 50 lines by default
    tail -50 "$selected_log"
    
    echo ""
    echo "💡 To view full log: cat \"$selected_log\""
    echo "💡 To follow log in real-time: tail -f \"$selected_log\""
}

# View all logs
view_all_logs() {
    echo "📄 View All Logs"
    echo "================"
    echo ""
    
    local logs_dir="$SCRIPT_DIR/logs"
    
    if [ ! -d "$logs_dir" ]; then
        echo "❌ No logs directory found: $logs_dir"
        return 0
    fi
    
    # Find all log files
    local all_logs=($(find "$logs_dir" -name "*.log" -type f | sort))
    
    if [ ${#all_logs[@]} -eq 0 ]; then
        echo "❌ No log files found"
        return 0
    fi
    
    echo "📋 Available log files:"
    local file_number=1
    for log_file in "${all_logs[@]}"; do
        local filename=$(basename "$log_file")
        local file_size=$(du -h "$log_file" | cut -f1)
        local file_date=$(stat -c %y "$log_file" 2>/dev/null || stat -f %Sm "$log_file" 2>/dev/null)
        echo "$file_number) $filename ($file_size) - $file_date"
        ((file_number++))
    done
    
    echo ""
    read -p "Enter log file number to view (1-${#all_logs[@]}): " choice
    
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#all_logs[@]} ]; then
        echo "❌ Invalid choice"
        return 0
    fi
    
    local selected_log="${all_logs[$((choice-1))]}"
    
    echo ""
    echo "📄 Viewing: $(basename "$selected_log")"
    echo "=========================================="
    echo ""
    
    # Show last 50 lines by default
    tail -50 "$selected_log"
    
    echo ""
    echo "💡 To view full log: cat \"$selected_log\""
    echo "💡 To follow log in real-time: tail -f \"$selected_log\""
}

# Clean old logs
clean_old_logs() {
    echo "🧹 Clean Old Logs"
    echo "================="
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
    echo "🔍 Finding log files older than $retention_days days..."
    
    # Find old log files (including cron logs with descriptive names)
    local old_logs=($(find "$logs_dir" -name "*.log" -type f -mtime +$retention_days))
    
    if [ ${#old_logs[@]} -eq 0 ]; then
        echo "✅ No log files older than $retention_days days found"
        return 0
    fi
    
    echo "📋 Found ${#old_logs[@]} old log file(s):"
    for log_file in "${old_logs[@]}"; do
        local filename=$(basename "$log_file")
        local file_size=$(du -h "$log_file" | cut -f1)
        local file_date=$(stat -c %y "$log_file" 2>/dev/null || stat -f %Sm "$log_file" 2>/dev/null)
        echo "  📄 $filename ($file_size) - $file_date"
    done
    
    echo ""
    read -p "Remove these old log files? (y/N): " confirm
    
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
            log_success "Removed $removed_count old log file(s)"
        fi
    else
        echo "❌ Operation cancelled"
    fi
}

# Show log statistics
show_log_stats() {
    echo "📊 Log Statistics"
    echo "================="
    echo ""
    
    local logs_dir="$SCRIPT_DIR/logs"
    
    if [ ! -d "$logs_dir" ]; then
        echo "❌ No logs directory found: $logs_dir"
        return 0
    fi
    
    echo "📁 Log Directory: $logs_dir"
    echo ""
    
    # Count log files
    local total_logs=$(find "$logs_dir" -name "*.log" -type f | wc -l)
    echo "📄 Total log files: $total_logs"
    
    if [ $total_logs -gt 0 ]; then
        # Total size
        local total_size=$(du -sh "$logs_dir" | cut -f1)
        echo "📊 Total size: $total_size"
        echo ""
        
        # Log files by type
        echo "📋 Log files by type:"
        echo "  🔄 Cron logs: $(find "$logs_dir" -name "*cron*.log" -type f | wc -l)"
        echo "  🏗️  Infrastructure logs: $(find "$logs_dir" -name "infrastructure_*.log" -type f | wc -l)"
        echo "  📝 Other logs: $(find "$logs_dir" -name "*.log" -type f ! -name "*cron*" ! -name "infrastructure_*" | wc -l)"
        echo ""
        
        # Recent logs
        echo "🕒 Recent log files (last 7 days):"
        find "$logs_dir" -name "*.log" -type f -mtime -7 -exec ls -lh {} \; | while read line; do
            local size=$(echo "$line" | awk '{print $5}')
            local date=$(echo "$line" | awk '{print $6" "$7" "$8}')
            local filename=$(echo "$line" | awk '{print $9}' | xargs basename)
            echo "  📄 $filename ($size) - $date"
        done
    fi
}

# Command line argument handler (only when script is executed directly)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ $# -gt 0 ]; then
        case "$1" in
            "view_cron_logs")
                view_cron_logs
                ;;
            "view_all_logs")
                view_all_logs
                ;;
            "clean_old_logs")
                clean_old_logs
                ;;
            "show_log_stats")
                show_log_stats
                ;;
            *)
                echo "❌ Unknown command: $1"
                echo "Available commands:"
                echo "  view_cron_logs - View cron log files"
                echo "  view_all_logs - View all log files"
                echo "  clean_old_logs - Clean old log files"
                echo "  show_log_stats - Show log statistics"
                exit 1
                ;;
        esac
    fi
fi
