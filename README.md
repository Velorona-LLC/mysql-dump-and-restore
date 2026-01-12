# MySQL Database Backup and Restore Tool

This repository contains scripts to backup and restore MySQL databases, particularly designed for AWS RDS instances but compatible with any MySQL database.

## Features

- **Flexible backup options**: Schema only, data only, or both
- **Table filtering**: Select specific tables or ignore certain tables
- **Safe restore**: Automatically creates a backup before restoring
- **Environment-based configuration**: Use `.env.sh` file for easy configuration
- **Connection validation**: Tests database connectivity before operations

## Prerequisites

- MySQL client tools (mysql, mysqldump)
- Bash shell
- Network access to source and target MySQL databases

## Installation

1. Install MySQL client tools:
   ```bash
   chmod +x install-dependency.sh
   ./install-dependency.sh
   ```

## Configuration

Create a `.env.sh` file in the project root with your database credentials:

```bash
# Source Database Configuration (for backup)
export SOURCE_DB_USER="your_username"
export SOURCE_DB_PASSWORD="your_password"
export SOURCE_DB_HOST="source-db-host.amazonaws.com"
export SOURCE_DB_PORT="3306"
export SOURCE_DB_NAME="your_database_name"

# Target Database Configuration (for restore)
export TARGET_DB_USER="your_username"
export TARGET_DB_PASSWORD="your_password"
export TARGET_DB_HOST="target-db-host.amazonaws.com"
export TARGET_DB_PORT="3306"
export TARGET_DB_NAME="your_database_name"
export TARGET_DB_BACKUP_NAME="your_database_name_backup"

# Dump file location
export DUMP_FILE="./dump.sql"

# Optional: Table filtering (uncomment to use)
# export SELECTED_TABLES="table1 table2 table3"  # Only dump these tables
# export IGNORED_TABLES="logs audit_trail"       # Ignore these tables
```

**Important**: Add `.env.sh` to your `.gitignore` to protect sensitive credentials!

## Usage

### Backup Database

Run the backup script:

```bash
chmod +x backup.sh
./backup.sh
```

The script will prompt you to select:

1. **Dump type**:
   - Schema only: Database structure without data
   - Data only: Data without structure
   - Both: Complete database dump

2. **Table filtering** (optional):
   - All tables: Dump everything
   - Selected tables: Specify which tables to include
   - Ignore tables: Specify which tables to exclude

Alternatively, pass the dump type as an argument:

```bash
./backup.sh schema  # Schema only
./backup.sh data    # Data only
./backup.sh both    # Both schema and data
```

### Restore Database

Run the restore script:

```bash
chmod +x restore.sh
./restore.sh
```

The restore process:
1. Tests connection to target database
2. Creates a backup of the existing database (if it exists) as `TARGET_DB_BACKUP_NAME`
3. Drops the existing target database
4. Creates a new empty database
5. Restores data from the dump file

**Warning**: The restore script will drop the existing database. Make sure you have a backup!

## Files

- `backup.sh` - Script to create database dumps from source database
- `restore.sh` - Script to restore database to target database
- `install-dependency.sh` - Installs MySQL client tools on Ubuntu
- `dump.sql` - Default location for database dump file
- `.env.sh` - Environment configuration file (create this yourself)

## Environment Variables

### Backup (Source Database)
- `SOURCE_DB_USER` - Database username
- `SOURCE_DB_PASSWORD` - Database password
- `SOURCE_DB_HOST` - Database host
- `SOURCE_DB_PORT` - Database port (default: 3306)
- `SOURCE_DB_NAME` - Database name to backup
- `SELECTED_TABLES` - Space-separated list of tables to include
- `IGNORED_TABLES` - Space-separated list of tables to exclude

### Restore (Target Database)
- `TARGET_DB_USER` - Database username
- `TARGET_DB_PASSWORD` - Database password
- `TARGET_DB_HOST` - Database host
- `TARGET_DB_PORT` - Database port (default: 3306)
- `TARGET_DB_NAME` - Database name to restore to
- `TARGET_DB_BACKUP_NAME` - Name for backup of existing database

### General
- `DUMP_FILE` - Path to dump file (default: ./dump.sql)

## Examples

### Backup specific tables only

In `.env.sh`:
```bash
export SELECTED_TABLES="users orders products"
```

Or when prompted, select option 2 and enter the table names.

### Backup all tables except logs

In `.env.sh`:
```bash
export IGNORED_TABLES="logs audit_trail session_data"
```

Or when prompted, select option 3 and enter the table names to ignore.

### Automated backup (non-interactive)

```bash
# Schema only
./backup.sh schema

# Data only
./backup.sh data

# Full backup
./backup.sh both
```

## Security Notes

- Never commit `.env.sh` to version control
- Use secure credentials and rotate them regularly
- The scripts create temporary config files in `/tmp/` which are automatically protected with `chmod 600`
- Consider using SSH tunnels or VPN for database connections over public networks

## Troubleshooting

### Connection errors
- Verify your database credentials in `.env.sh`
- Check network connectivity to database host
- Ensure database port is accessible (check firewall rules)
- For RDS, verify security group allows your IP

### Permission errors
- Ensure the database user has necessary privileges (SELECT for backup, CREATE/DROP for restore)
- For restore operations, user needs CREATE DATABASE and DROP DATABASE privileges

## License

MIT License - Feel free to use and modify as needed.
