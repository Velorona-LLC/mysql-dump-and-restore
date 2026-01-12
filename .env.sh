#!/bin/bash

# Environment variables for database backup and restore scripts

# Source database configuration (for backup.sh)
export SOURCE_DB_USER=${SOURCE_DB_USER:-root}
export SOURCE_DB_PASSWORD="Password@123"
export SOURCE_DB_HOST=${SOURCE_DB_HOST:-localhost}
export SOURCE_DB_PORT=${SOURCE_DB_PORT:-3306}
export SOURCE_DB_NAME="velorona_local"
# Dump type: "schema", "data", or "both" (for backup.sh)
export DUMP_TYPE=${DUMP_TYPE:-both}
# Table filtering options (for backup.sh)
# TABLE_MODE can be: "" (all tables), "selected", or "ignore"
export TABLE_MODE=${TABLE_MODE:-}
# Tables separated by space for selected or ignored tables
export SELECTED_TABLES=${SELECTED_TABLES:-}
export IGNORED_TABLES=${IGNORED_TABLES:-}

# Target database configuration (for restore.sh)
export TARGET_DB_USER=${TARGET_DB_USER:-root}
export TARGET_DB_PASSWORD="Password@123"
export TARGET_DB_HOST=${TARGET_DB_HOST:-localhost}
export TARGET_DB_PORT=${TARGET_DB_PORT:-3306}
export TARGET_DB_NAME=${TARGET_DB_NAME:-db}
export TARGET_DB_BACKUP_NAME=${TARGET_DB_BACKUP_NAME:-${TARGET_DB_NAME}_backup}

# Dump file
export DUMP_FILE=${DUMP_FILE:-dump.sql}