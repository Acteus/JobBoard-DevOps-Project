#!/bin/bash

# JobBoard Database Setup Script
# This script helps set up the MySQL database for the Job Board application

set -e

# Configuration
DB_HOST=${DB_HOST:-"localhost"}
DB_USER=${DB_USER:-"root"}
DB_PASS=${DB_PASS:-""}
DB_NAME=${DB_NAME:-"jobboard"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}JobBoard Database Setup${NC}"
echo "========================"

# Check if MySQL client is installed
if ! command -v mysql &> /dev/null; then
    echo -e "${RED}Error: MySQL client is not installed.${NC}"
    echo "Please install MySQL client and try again."
    exit 1
fi

# Check if SQL file exists
SQL_FILE="$(dirname "$0")/setup-db.sql"
if [ ! -f "$SQL_FILE" ]; then
    echo -e "${RED}Error: SQL file not found at $SQL_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}Setting up database: $DB_NAME${NC}"
echo -e "${YELLOW}Database host: $DB_HOST${NC}"
echo -e "${YELLOW}Database user: $DB_USER${NC}"

# Build MySQL command
MYSQL_CMD="mysql"
if [ ! -z "$DB_PASS" ]; then
    MYSQL_CMD="$MYSQL_CMD -p$DB_PASS"
fi

# Execute SQL script
echo -e "${YELLOW}Executing SQL script...${NC}"
$MYSQL_CMD -h "$DB_HOST" -u "$DB_USER" -D "$DB_NAME" < "$SQL_FILE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Database setup completed successfully!${NC}"
    echo ""
    echo "Database: $DB_NAME"
    echo "Tables created:"
    echo "  - jobs (main job listings)"
    echo "  - users (for future authentication)"
    echo "  - applications (for job applications)"
    echo ""
    echo "Sample data has been inserted into the jobs table."
    echo ""
    echo -e "${GREEN}Setup complete!${NC}"
else
    echo -e "${RED}Error: Database setup failed.${NC}"
    echo "Please check your MySQL connection details and try again."
    exit 1
fi