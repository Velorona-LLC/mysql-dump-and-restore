#!/bin/bash
set -e

# Load environment variables from .env.sh if it exists
if [ -f ".env.sh" ]; then
    source ./.env.sh
fi

# Read database configuration from environment variables
DB_USER=${TARGET_DB_USER}
DB_PASSWORD=${TARGET_DB_PASSWORD}
DB_HOST=${TARGET_DB_HOST}
DB_PORT=${TARGET_DB_PORT}
DB_NAME=${TARGET_DB_NAME}
DB_BACKUP_NAME=${TARGET_DB_BACKUP_NAME}
DUMP_FILE=${DUMP_FILE}

# Validate required environment variables
if [ -z "$DB_PASSWORD" ]; then
    echo "Error: DB_PASSWORD environment variable is not set."
    exit 1
fi

# Validate that the dump file exists
if [ ! -f "$DUMP_FILE" ]; then
    echo "Error: Dump file $DUMP_FILE does not exist."
    exit 1
fi

# Create MySQL target configuration file
cat > /tmp/rds-target.cnf <<EOF
[client]
user=${DB_USER}
password=${DB_PASSWORD}
host=${DB_HOST}
port=${DB_PORT}
protocol=TCP
EOF

# Protect the configuration file
chmod 600 /tmp/rds-target.cnf  

# Test connection to target database
echo "Testing connection to target database..."
if ! mysql --defaults-extra-file=/tmp/rds-target.cnf -e "SELECT 1;" > /dev/null 2>&1; then
    echo "Error: Cannot connect to the target MySQL database at ${DB_HOST}:${DB_PORT} as ${DB_USER}."
    echo "Please check your TARGET_DB_* environment variables and network connectivity."
    exit 1
fi
echo "Connection successful."

# Create a backup of current database into ${DB_BACKUP_NAME} only if it exists
echo "Creating backup of database ${DB_NAME} as ${DB_BACKUP_NAME} if it exists..."
if mysql --defaults-extra-file=/tmp/rds-target.cnf -e "SHOW DATABASES LIKE '${DB_NAME}';" | grep -q "${DB_NAME}"; then
  # Create the backup database first
  mysql --defaults-extra-file=/tmp/rds-target.cnf -e "DROP DATABASE IF EXISTS ${DB_BACKUP_NAME};"
  mysql --defaults-extra-file=/tmp/rds-target.cnf -e "CREATE DATABASE ${DB_BACKUP_NAME};"
  
  # Now dump and restore to backup database
  mysqldump --defaults-extra-file=/tmp/rds-target.cnf \
    --single-transaction \
    --set-gtid-purged=OFF \
    --column-statistics=0 \
    --no-tablespaces \
    ${DB_NAME} \
  | mysql --defaults-extra-file=/tmp/rds-target.cnf ${DB_BACKUP_NAME}
  echo "Backup of database ${DB_NAME} created successfully as ${DB_BACKUP_NAME}."
fi

# Safely drop the existing database ${DB_NAME}
echo "Dropping existing database ${DB_NAME}..."
mysql --defaults-extra-file=/tmp/rds-target.cnf -e "DROP DATABASE IF EXISTS ${DB_NAME};"
echo "Database ${DB_NAME} dropped successfully."

# Create a new database ${DB_NAME}
echo "Creating new database ${DB_NAME}..."
mysql --defaults-extra-file=/tmp/rds-target.cnf -e "CREATE DATABASE ${DB_NAME};"
echo "Database ${DB_NAME} created successfully."

# Import the .sql dump file into the new database ${DB_NAME}
echo "Restoring database ${DB_NAME} from dump file ${DUMP_FILE}..."
mysql --defaults-extra-file=/tmp/rds-target.cnf ${DB_NAME} < ${DUMP_FILE}
echo "Database ${DB_NAME} restored successfully from ${DUMP_FILE}."