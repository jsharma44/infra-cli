#!/bin/bash

# 🔧 Environment Variables Loader
# Centralized environment variable loading for all infrastructure scripts
# This file should be sourced by all scripts to ensure consistent environment setup

# Prevent circular dependencies
if [ "${ENV_LOADED:-}" = "true" ]; then
    return 0
fi

# Get the project root directory (parent of scripts directory)
if [ -n "${BASH_SOURCE[0]}" ] && [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    # Sourced from another script
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
else
    # Direct execution or bash -c - use current directory
    SCRIPT_DIR="$(pwd)"
fi

# Load environment variables from .env file if it exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    # Source all variables from .env file
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
    
    # Export simple variables (skip problematic ones)
    # The set -a and source already loaded all variables, we just need to export them
    # Use a safer approach by explicitly exporting known good variables
    export EMAIL DOMAIN DEPLOYMENT_ENV
    export SSL_COUNTRY SSL_STATE SSL_CITY SSL_ORG SSL_OU SSL_CN SSL_PREFIX
    export DOCKER_USER USER_PASSWORD DOCKER_NETWORK
    export MYSQL_ROOT_PASSWORD MYSQL_PORT
    export POSTGRES_PASSWORD POSTGRES_USER POSTGRES_DB POSTGRES_PORT
    export REDIS_PASSWORD REDIS_PORT REDIS_SSL_PORT REDIS_USER
    export FLEET_MYSQL_DATABASE FLEET_MYSQL_USERNAME FLEET_MYSQL_PASSWORD FLEET_SERVER_PRIVATE_KEY
    export TB_INFRA_TOKEN TB_INFRA_WORKSPACE TB_INFRA_ORGANIZATION TB_INFRA_USER
    export CLOUDFLARE_API_TOKEN
    export BACKUP_ENABLED BACKUP_RETENTION_DAYS BACKUP_COMPRESSION BACKUP_LOCAL_DIR
    export S3_BACKUP_ENABLED S3_BUCKET_NAME S3_REGION S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY S3_ENDPOINT_URL

    # Convert multi-line WSTEP variables to clean PEM format (no YAML indentation)
    if [ -n "${FLEET_MDM_WINDOWS_WSTEP_IDENTITY_CERT_BYTES:-}" ]; then
        FLEET_MDM_WINDOWS_WSTEP_IDENTITY_CERT_BYTES=$(printf '%s\n' "${FLEET_MDM_WINDOWS_WSTEP_IDENTITY_CERT_BYTES}" | sed 's/\\n/\n/g' | sed '/^[[:space:]]*$/d')
        export FLEET_MDM_WINDOWS_WSTEP_IDENTITY_CERT_BYTES
    fi
    if [ -n "${FLEET_MDM_WINDOWS_WSTEP_IDENTITY_KEY_BYTES:-}" ]; then
        FLEET_MDM_WINDOWS_WSTEP_IDENTITY_KEY_BYTES=$(printf '%s\n' "${FLEET_MDM_WINDOWS_WSTEP_IDENTITY_KEY_BYTES}" | sed 's/\\n/\n/g' | sed '/^[[:space:]]*$/d')
        export FLEET_MDM_WINDOWS_WSTEP_IDENTITY_KEY_BYTES
    fi
fi

# Set default values for common variables
BACKUP_LOCAL_DIR=${BACKUP_LOCAL_DIR:-./backups}
DOCKER_NETWORK=${DOCKER_NETWORK:-my-network}

# Export all environment variables to make them available to child processes
export EMAIL DOMAIN DEPLOYMENT_ENV
export SSL_COUNTRY SSL_STATE SSL_CITY SSL_ORG SSL_OU SSL_CN SSL_PREFIX
export DOCKER_USER USER_PASSWORD DOCKER_NETWORK
export MYSQL_ROOT_PASSWORD MYSQL_PORT
export POSTGRES_PASSWORD POSTGRES_USER POSTGRES_DB POSTGRES_PORT
export REDIS_PASSWORD REDIS_PORT REDIS_SSL_PORT REDIS_USER
export FLEET_MYSQL_DATABASE FLEET_MYSQL_USERNAME FLEET_MYSQL_PASSWORD FLEET_SERVER_PRIVATE_KEY
export FLEET_MDM_WINDOWS_WSTEP_IDENTITY_CERT_BYTES FLEET_MDM_WINDOWS_WSTEP_IDENTITY_KEY_BYTES
export TB_INFRA_TOKEN TB_INFRA_WORKSPACE TB_INFRA_ORGANIZATION TB_INFRA_USER
export CLOUDFLARE_API_TOKEN
export BACKUP_ENABLED BACKUP_RETENTION_DAYS BACKUP_COMPRESSION BACKUP_LOCAL_DIR
export S3_BACKUP_ENABLED S3_BUCKET_NAME S3_REGION S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY S3_ENDPOINT_URL

# Mark environment as loaded to prevent circular dependencies
export ENV_LOADED=true
