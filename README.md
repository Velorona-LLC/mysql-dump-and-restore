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

Configuration is provided via environment variables. A sample file `/.env.example` is included — copy it to `/.env` and edit values before running the scripts:

```bash
# Copy the example and edit
cp .env.example .env

# Then edit `.env` and set your credentials and options.
```

The repository also provides `./.env.sh` which loads `./.env` and exports variables used by `backup.sh` and `restore.sh`.

Example variables (edit in `/.env`):

```bash
# Source (backup) configuration
SOURCE_DB_USER=root
SOURCE_DB_PASSWORD=Password@123
SOURCE_DB_HOST=localhost
SOURCE_DB_PORT=3306
SOURCE_DB_NAME=db

# Dump behaviour
DUMP_TYPE=both  # "schema", "data", or "both"
TABLE_MODE=      # "" (all), "selected", or "ignore"
SELECTED_TABLES= # space-separated table names
IGNORED_TABLES=  # space-separated table names

# Target (restore) configuration
TARGET_DB_USER=root
TARGET_DB_PASSWORD=Password@123
TARGET_DB_HOST=localhost
TARGET_DB_PORT=3306
TARGET_DB_NAME=db
TARGET_DB_BACKUP_NAME=${TARGET_DB_NAME}_backup

# Dump file
DUMP_FILE=dump.sql
```

**Important**: Add `/.env` (or `/.env.sh` if you create that) to your `.gitignore` to keep secrets out of version control.

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

Below are the environment variables used by the scripts and their defaults (as provided in `/.env.sh` when not set):

- `SOURCE_DB_USER`: Database username (default: `root`)
- `SOURCE_DB_PASSWORD`: Database password (default: `Password@123`) — keep secrets out of VCS
- `SOURCE_DB_HOST`: Database host (default: `localhost`)
- `SOURCE_DB_PORT`: Database port (default: `3306`)
- `SOURCE_DB_NAME`: Database name to backup (default: `db`)
- `DUMP_TYPE`: Dump type — `schema`, `data`, or `both` (default: `both`)
- `TABLE_MODE`: Table mode: `` (all tables), `selected`, or `ignore` (default: empty)
- `SELECTED_TABLES`: Space-separated list of tables to include (used when `TABLE_MODE=selected`)
- `IGNORED_TABLES`: Space-separated list of tables to exclude (used when `TABLE_MODE=ignore`)

- `TARGET_DB_USER`: Database username for restore (default: `root`)
- `TARGET_DB_PASSWORD`: Database password for restore (default: `Password@123`) — keep secrets out of VCS
- `TARGET_DB_HOST`: Target DB host (default: `localhost`)
- `TARGET_DB_PORT`: Target DB port (default: `3306`)
- `TARGET_DB_NAME`: Target database name for restore (default: `db`)
- `TARGET_DB_BACKUP_NAME`: Name for backup of existing target DB (default: `${TARGET_DB_NAME}_backup`)

- `DUMP_FILE`: Path to dump file (default: `./dump.sql`)

Note: The `/.env.sh` script will `set -a` and source `./.env` to export variables. Using `/.env.example` and `/.env` keeps credentials out of the repository while documenting defaults.

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
