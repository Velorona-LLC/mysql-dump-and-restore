#!/bin/bash
set -e

# Load environment variables from .env.sh if it exists
if [ -f ".env.sh" ]; then
    source ./.env.sh
fi

# Read source database configuration from environment variables
SOURCE_DB_USER=${SOURCE_DB_USER}
SOURCE_DB_PASSWORD=${SOURCE_DB_PASSWORD}
SOURCE_DB_HOST=${SOURCE_DB_HOST}
SOURCE_DB_PORT=${SOURCE_DB_PORT}
SOURCE_DB_NAME=${SOURCE_DB_NAME}

DUMP_FILE=${DUMP_FILE}

# Dump type - can be overridden by command-line argument or user input
DUMP_TYPE=${1:-}

# If dump type not provided as argument, ask user
if [ -z "$DUMP_TYPE" ]; then
    echo "Select dump type:"
    echo "1) Schema only"
    echo "2) Data only"
    echo "3) Both (schema + data)"
    read -p "Enter your choice (1-3): " choice
    case $choice in
        1) DUMP_TYPE="schema" ;;
        2) DUMP_TYPE="data" ;;
        3) DUMP_TYPE="both" ;;
        *) echo "Invalid choice. Defaulting to both."; DUMP_TYPE="both" ;;
    esac
fi

# Table selection options - read from environment or prompt user
TABLE_MODE=${TABLE_MODE:-}
SELECTED_TABLES=${SELECTED_TABLES:-}
IGNORED_TABLES=${IGNORED_TABLES:-}

# If table mode not set via environment, ask user
if [ -z "$TABLE_MODE" ] && [ -z "$SELECTED_TABLES" ] && [ -z "$IGNORED_TABLES" ]; then
    echo ""
    echo "Select table filtering option:"
    echo "1) All tables (default)"
    echo "2) Selected tables only"
    echo "3) Ignore specific tables"
    read -p "Enter your choice (1-3): " table_choice

    case $table_choice in
        2)
            TABLE_MODE="selected"
            echo "Enter table names to dump (space-separated):"
            read -p "Tables: " SELECTED_TABLES
            if [ -z "$SELECTED_TABLES" ]; then
                echo "Error: No tables specified. Exiting."
                exit 1
            fi
            ;;
        3)
            TABLE_MODE="ignore"
            echo "Enter table names to ignore (space-separated):"
            read -p "Tables to ignore: " IGNORED_TABLES
            if [ -z "$IGNORED_TABLES" ]; then
                echo "Warning: No tables specified to ignore. Dumping all tables."
                TABLE_MODE=""
            fi
            ;;
        *)
            TABLE_MODE=""
            echo "Dumping all tables."
            ;;
    esac
else
    # Using environment variables
    if [ -n "$SELECTED_TABLES" ]; then
        TABLE_MODE="selected"
        echo "Using environment: Dumping selected tables: $SELECTED_TABLES"
    elif [ -n "$IGNORED_TABLES" ]; then
        TABLE_MODE="ignore"
        echo "Using environment: Ignoring tables: $IGNORED_TABLES"
    else
        echo "Using environment: Dumping all tables."
    fi
fi

# Validate required environment variables
if [ -z "$SOURCE_DB_PASSWORD" ]; then
    echo "Error: SOURCE_DB_PASSWORD environment variable is not set."
    exit 1
fi

# Create MySQL source configuration file
cat > /tmp/rds-source.cnf <<EOF
[client]
user=${SOURCE_DB_USER}
password=${SOURCE_DB_PASSWORD}
host=${SOURCE_DB_HOST}
port=${SOURCE_DB_PORT}
protocol=TCP
EOF

# Protect the configuration file
chmod 600 /tmp/rds-source.cnf

# Test connection to source database
echo "Testing connection to source database..."
if ! mysql --defaults-extra-file=/tmp/rds-source.cnf -e "SELECT 1;" > /dev/null 2>&1; then
    echo "Error: Cannot connect to the source MySQL database at ${SOURCE_DB_HOST}:${SOURCE_DB_PORT} as ${SOURCE_DB_USER}."
    echo "Please check your SOURCE_DB_* environment variables and network connectivity."
    exit 1
fi
echo "Connection successful."

# Create dump from source database based on selected type
echo "Creating ${DUMP_TYPE} dump of database ${SOURCE_DB_NAME} into file ${DUMP_FILE}..."

MYSQLDUMP_ARGS="--defaults-extra-file=/tmp/rds-source.cnf \
  --single-transaction \
  --set-gtid-purged=OFF \
  --column-statistics=0 \
  --no-tablespaces"

# Add table-specific arguments
if [ "$TABLE_MODE" = "selected" ]; then
    TABLE_ARGS="$SELECTED_TABLES"
    echo "Dumping selected tables: $SELECTED_TABLES"
elif [ "$TABLE_MODE" = "ignore" ]; then
    TABLE_ARGS=""
    for table in $IGNORED_TABLES; do
        TABLE_ARGS="$TABLE_ARGS --ignore-table=${SOURCE_DB_NAME}.${table}"
    done
    echo "Ignoring tables: $IGNORED_TABLES"
else
    TABLE_ARGS=""
fi

case $DUMP_TYPE in
    schema)
        mysqldump $MYSQLDUMP_ARGS --no-data ${SOURCE_DB_NAME} $TABLE_ARGS > ${DUMP_FILE}
        ;;
    data)
        mysqldump $MYSQLDUMP_ARGS --no-create-info ${SOURCE_DB_NAME} $TABLE_ARGS > ${DUMP_FILE}
        ;;
    both)
        mysqldump $MYSQLDUMP_ARGS ${SOURCE_DB_NAME} $TABLE_ARGS > ${DUMP_FILE}
        ;;
esac

echo "Dump created successfully: ${DUMP_FILE}"