#!/bin/bash

# 🗄️ Database & User Management Functions
# Database and user management for MySQL and PostgreSQL
# Separated for better organization

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/scripts/env.sh"

# Load utility functions for logging
if [ -f "$SCRIPT_DIR/scripts/core.sh" ]; then
    source "$SCRIPT_DIR/scripts/core.sh"
fi


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# Check if database service is running
check_database_service() {
    local db_type="$1"
    case "$db_type" in
        "mysql")
            if ! docker ps | grep -q mysql; then
                log_error "MySQL container is not running"
                return 1
            fi
            ;;
        "postgres")
            if ! docker ps | grep -q postgres; then
                log_error "PostgreSQL container is not running"
                return 1
            fi
            ;;
        *)
            log_error "Unsupported database type: $db_type"
            return 1
            ;;
    esac
    return 0
}

# Execute MySQL command
execute_mysql() {
    local command="$1"
    local user="${MYSQL_USER:-root}"
    docker exec mysql mysql -u"$user" -p"$MYSQL_ROOT_PASSWORD" -e "$command" 2>/dev/null
}

# Execute PostgreSQL command
execute_postgres() {
    local command="$1"
    docker exec postgres psql -U "$POSTGRES_USER" -d postgres -c "$command" 2>/dev/null
}

# =============================================================================
# DATABASE MANAGEMENT FUNCTIONS
# =============================================================================

# List all databases
list_databases() {
    echo "🗄️  List All Databases"
    echo "======================"
    echo ""
    
    echo "Available databases: mysql, postgres"
    echo ""
    read -p "Enter database type: " db_type
    
    if [ -z "$db_type" ]; then
        echo "❌ Database type cannot be empty"
        return 0
    fi
    
    if ! check_database_service "$db_type"; then
        return 1
    fi
    
    echo ""
    echo "📋 Databases in $db_type:"
    echo "========================="
    
    case "$db_type" in
        "mysql")
            execute_mysql "SHOW DATABASES;" | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys" | while read db; do
                if [ -n "$db" ]; then
                    echo "  📄 $db"
                fi
            done
            ;;
        "postgres")
            execute_postgres "SELECT datname FROM pg_database WHERE datistemplate = false;" | grep -v "datname\|^[[:space:]]*$\|^[[:space:]]*-" | grep -v "^[[:space:]]*(" | while read db; do
                if [ -n "$db" ] && [ "$db" != "postgres" ] || [ "$db" = "postgres" ]; then
                    echo "  📄 $db"
                fi
            done
            ;;
        *)
            echo "❌ Unsupported database type: $db_type"
            return 1
            ;;
    esac
}

# Create database
create_database() {
    echo "➕ Create Database"
    echo "================="
    echo ""
    
    echo "Available databases: mysql, postgres"
    echo ""
    read -p "Enter database type: " db_type
    
    if [ -z "$db_type" ]; then
        echo "❌ Database type cannot be empty"
        return 0
    fi
    
    if ! check_database_service "$db_type"; then
        return 1
    fi
    
    read -p "Enter database name: " db_name
    
    if [ -z "$db_name" ]; then
        echo "❌ Database name cannot be empty"
        return 0
    fi
    
    echo ""
    echo "Creating database '$db_name' in $db_type..."
    
    case "$db_type" in
        "mysql")
            if execute_mysql "CREATE DATABASE \`$db_name\`;"; then
                log_success "Database '$db_name' created successfully in MySQL"
            else
                log_error "Failed to create database '$db_name' in MySQL"
            fi
            ;;
        "postgres")
            if execute_postgres "CREATE DATABASE \"$db_name\";"; then
                log_success "Database '$db_name' created successfully in PostgreSQL"
            else
                log_error "Failed to create database '$db_name' in PostgreSQL"
            fi
            ;;
        *)
            echo "❌ Unsupported database type: $db_type"
            return 1
            ;;
    esac
}

# Rename database
rename_database() {
    echo "🔄 Rename Database"
    echo "=================="
    echo ""
    
    echo "Available databases: mysql, postgres"
    echo ""
    read -p "Enter database type: " db_type
    
    if [ -z "$db_type" ]; then
        echo "❌ Database type cannot be empty"
        return 0
    fi
    
    if ! check_database_service "$db_type"; then
        return 1
    fi
    
    read -p "Enter current database name: " old_name
    read -p "Enter new database name: " new_name
    
    if [ -z "$old_name" ] || [ -z "$new_name" ]; then
        echo "❌ Database names cannot be empty"
        return 0
    fi
    
    echo ""
    echo "⚠️  This will rename database '$old_name' to '$new_name'"
    read -p "Are you sure? (y/N): " confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "❌ Operation cancelled"
        return 0
    fi
    
    echo "Renaming database '$old_name' to '$new_name' in $db_type..."
    
    case "$db_type" in
        "mysql")
            # MySQL doesn't support direct rename, so we create new and drop old
            echo "Creating new database '$new_name'..."
            if execute_mysql "CREATE DATABASE \`$new_name\`;"; then
                echo "✅ New database '$new_name' created successfully"
                echo "Dumping data from '$old_name' to '$new_name'..."
                if docker exec mysql mysqldump -u"$MYSQL_USER" -p"$MYSQL_ROOT_PASSWORD" "$old_name" 2>/dev/null | docker exec -i mysql mysql -u"$MYSQL_USER" -p"$MYSQL_ROOT_PASSWORD" "$new_name" 2>/dev/null; then
                    echo "✅ Data copied successfully from '$old_name' to '$new_name'"
                    echo "Dropping old database '$old_name'..."
                    if execute_mysql "DROP DATABASE \`$old_name\`;"; then
                        echo "✅ Old database '$old_name' dropped successfully"
                        log_success "Database renamed from '$old_name' to '$new_name' in MySQL"
                    else
                        log_error "Failed to drop old database '$old_name' in MySQL"
                        echo "⚠️  Both databases exist: '$old_name' and '$new_name'"
                    fi
                else
                    log_error "Failed to copy data from '$old_name' to '$new_name' in MySQL"
                    echo "Cleaning up new database '$new_name'..."
                    execute_mysql "DROP DATABASE \`$new_name\`;"
                fi
            else
                log_error "Failed to create new database '$new_name' in MySQL"
                echo "Database '$new_name' may already exist"
            fi
            ;;
        "postgres")
            if execute_postgres "ALTER DATABASE \"$old_name\" RENAME TO \"$new_name\";"; then
                log_success "Database renamed from '$old_name' to '$new_name' in PostgreSQL"
            else
                log_error "Failed to rename database in PostgreSQL"
            fi
            ;;
        *)
            echo "❌ Unsupported database type: $db_type"
            return 1
            ;;
    esac
}

# Delete database
delete_database() {
    echo "🗑️  Delete Database"
    echo "==================="
    echo ""
    
    echo "Available databases: mysql, postgres"
    echo ""
    read -p "Enter database type: " db_type
    
    if [ -z "$db_type" ]; then
        echo "❌ Database type cannot be empty"
        return 0
    fi
    
    if ! check_database_service "$db_type"; then
        return 1
    fi
    
    read -p "Enter database name to delete: " db_name
    
    if [ -z "$db_name" ]; then
        echo "❌ Database name cannot be empty"
        return 0
    fi
    
    echo ""
    echo "⚠️  This will PERMANENTLY DELETE database '$db_name'"
    echo "⚠️  This action cannot be undone!"
    read -p "Are you sure? Type 'DELETE' to confirm: " confirm
    
    if [ "$confirm" != "DELETE" ]; then
        echo "❌ Operation cancelled"
        return 0
    fi
    
    echo "Deleting database '$db_name' from $db_type..."
    
    case "$db_type" in
        "mysql")
            if execute_mysql "DROP DATABASE \`$db_name\`;"; then
                log_success "Database '$db_name' deleted successfully from MySQL"
            else
                log_error "Failed to delete database '$db_name' from MySQL"
            fi
            ;;
        "postgres")
            if execute_postgres "DROP DATABASE \"$db_name\";"; then
                log_success "Database '$db_name' deleted successfully from PostgreSQL"
            else
                log_error "Failed to delete database '$db_name' from PostgreSQL"
            fi
            ;;
        *)
            echo "❌ Unsupported database type: $db_type"
            return 1
            ;;
    esac
}

# =============================================================================
# USER MANAGEMENT FUNCTIONS
# =============================================================================

# List all users
list_users() {
    echo "👥 List All Users"
    echo "================="
    echo ""
    
    echo "Available databases: mysql, postgres"
    echo ""
    read -p "Enter database type: " db_type
    
    if [ -z "$db_type" ]; then
        echo "❌ Database type cannot be empty"
        return 0
    fi
    
    if ! check_database_service "$db_type"; then
        return 1
    fi
    
    echo ""
    echo "👥 Users in $db_type:"
    echo "===================="
    
    case "$db_type" in
        "mysql")
            execute_mysql "SELECT User, Host FROM mysql.user WHERE User != 'root' AND User != 'mysql.sys';" | grep -v "User\|Host" | while read user host; do
                if [ -n "$user" ]; then
                    echo "  👤 $user@$host"
                fi
            done
            ;;
        "postgres")
            execute_postgres "SELECT usename FROM pg_user WHERE usename != 'postgres';" | grep -v "usename\|^[[:space:]]*$\|^[[:space:]]*-" | grep -v "^[[:space:]]*(" | while read user; do
                if [ -n "$user" ]; then
                    echo "  👤 $user"
                fi
            done
            ;;
        *)
            echo "❌ Unsupported database type: $db_type"
            return 1
            ;;
    esac
}

# Add user
add_user() {
    echo "➕ Add User"
    echo "==========="
    echo ""
    
    echo "Available databases: mysql, postgres"
    echo ""
    read -p "Enter database type: " db_type
    
    if [ -z "$db_type" ]; then
        echo "❌ Database type cannot be empty"
        return 0
    fi
    
    if ! check_database_service "$db_type"; then
        return 1
    fi
    
    read -p "Enter username: " username
    read -p "Enter password: " -s password
    echo ""
    
    if [ -z "$username" ] || [ -z "$password" ]; then
        echo "❌ Username and password cannot be empty"
        return 0
    fi
    
    echo ""
    echo "Creating user '$username' in $db_type..."
    
    case "$db_type" in
        "mysql")
            if execute_mysql "CREATE USER '$username'@'%' IDENTIFIED BY '$password';" && \
               execute_mysql "GRANT ALL PRIVILEGES ON *.* TO '$username'@'%';" && \
               execute_mysql "FLUSH PRIVILEGES;"; then
                log_success "User '$username' created successfully in MySQL"
            else
                log_error "Failed to create user '$username' in MySQL"
            fi
            ;;
        "postgres")
            if execute_postgres "CREATE USER \"$username\" WITH PASSWORD '$password';" && \
               execute_postgres "GRANT ALL PRIVILEGES ON DATABASE postgres TO \"$username\";"; then
                log_success "User '$username' created successfully in PostgreSQL"
            else
                log_error "Failed to create user '$username' in PostgreSQL"
            fi
            ;;
        *)
            echo "❌ Unsupported database type: $db_type"
            return 1
            ;;
    esac
}

# Update user password
update_user_password() {
    echo "🔑 Update User Password"
    echo "======================="
    echo ""
    
    echo "Available databases: mysql, postgres"
    echo ""
    read -p "Enter database type: " db_type
    
    if [ -z "$db_type" ]; then
        echo "❌ Database type cannot be empty"
        return 0
    fi
    
    if ! check_database_service "$db_type"; then
        return 1
    fi
    
    read -p "Enter username: " username
    read -p "Enter new password: " -s password
    echo ""
    
    if [ -z "$username" ] || [ -z "$password" ]; then
        echo "❌ Username and password cannot be empty"
        return 0
    fi
    
    echo ""
    echo "Updating password for user '$username' in $db_type..."
    
    case "$db_type" in
        "mysql")
            if execute_mysql "ALTER USER '$username'@'%' IDENTIFIED BY '$password';" && \
               execute_mysql "FLUSH PRIVILEGES;"; then
                log_success "Password updated successfully for user '$username' in MySQL"
            else
                log_error "Failed to update password for user '$username' in MySQL"
            fi
            ;;
        "postgres")
            if execute_postgres "ALTER USER \"$username\" WITH PASSWORD '$password';"; then
                log_success "Password updated successfully for user '$username' in PostgreSQL"
            else
                log_error "Failed to update password for user '$username' in PostgreSQL"
            fi
            ;;
        *)
            echo "❌ Unsupported database type: $db_type"
            return 1
            ;;
    esac
}

# Delete user
delete_user() {
    echo "🗑️  Delete User"
    echo "==============="
    echo ""
    
    echo "Available databases: mysql, postgres"
    echo ""
    read -p "Enter database type: " db_type
    
    if [ -z "$db_type" ]; then
        echo "❌ Database type cannot be empty"
        return 0
    fi
    
    if ! check_database_service "$db_type"; then
        return 1
    fi
    
    read -p "Enter username to delete: " username
    
    if [ -z "$username" ]; then
        echo "❌ Username cannot be empty"
        return 0
    fi
    
    echo ""
    echo "⚠️  This will PERMANENTLY DELETE user '$username'"
    echo "⚠️  This action cannot be undone!"
    read -p "Are you sure? Type 'DELETE' to confirm: " confirm
    
    if [ "$confirm" != "DELETE" ]; then
        echo "❌ Operation cancelled"
        return 0
    fi
    
    echo "Deleting user '$username' from $db_type..."
    
    case "$db_type" in
        "mysql")
            if execute_mysql "DROP USER '$username'@'%';" && \
               execute_mysql "FLUSH PRIVILEGES;"; then
                log_success "User '$username' deleted successfully from MySQL"
            else
                log_error "Failed to delete user '$username' from MySQL"
            fi
            ;;
        "postgres")
            # First revoke all privileges, then drop the user
            if execute_postgres "REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM \"$username\";" && \
               execute_postgres "REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM \"$username\";" && \
               execute_postgres "REVOKE ALL PRIVILEGES ON DATABASE postgres FROM \"$username\";" && \
               execute_postgres "DROP USER \"$username\";"; then
                log_success "User '$username' deleted successfully from PostgreSQL"
            else
                log_error "Failed to delete user '$username' from PostgreSQL"
            fi
            ;;
        *)
            echo "❌ Unsupported database type: $db_type"
            return 1
            ;;
    esac
}

# =============================================================================
# MAIN FUNCTIONS
# =============================================================================

# Database management menu
database_management() {
    echo "🗄️  Database Management"
    echo "======================="
    echo ""
    echo "1) 📋 List All Databases"
    echo "2) ➕ Create Database"
    echo "3) 🔄 Rename Database"
    echo "4) 🗑️  Delete Database"
    echo "5) 👥 List All Users"
    echo "6) ➕ Add User"
    echo "7) 🔑 Update User Password"
    echo "8) 🗑️  Delete User"
    echo "9) 🔙 Back to Main Menu"
    echo ""
    
    read -p "Enter your choice (1-9): " choice
    
    case $choice in
        1) list_databases ;;
        2) create_database ;;
        3) rename_database ;;
        4) delete_database ;;
        5) list_users ;;
        6) add_user ;;
        7) update_user_password ;;
        8) delete_user ;;
        9) return 0 ;;
        *) echo "❌ Invalid choice" ;;
    esac
}

# Command line argument handler (only when script is executed directly)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    if [ $# -gt 0 ]; then
        case "$1" in
            "list-databases") list_databases ;;
            "create-database") create_database ;;
            "rename-database") rename_database ;;
            "delete-database") delete_database ;;
            "list-users") list_users ;;
            "add-user") add_user ;;
            "update-user-password") update_user_password ;;
            "delete-user") delete_user ;;
            "menu") database_management ;;
            *) echo "Usage: $0 {list-databases|create-database|rename-database|delete-database|list-users|add-user|update-user-password|delete-user|menu}" ;;
        esac
    else
        database_management
    fi
fi
