#!/bin/bash

# JobBoard Development Setup Script
# This script helps set up the development environment locally

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}JobBoard Development Setup${NC}"
echo "=========================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}Node.js is not installed. Installing Node.js...${NC}"
    # Install Node.js using NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

echo -e "${YELLOW}Installing frontend dependencies...${NC}"
cd frontend
if [ -f "package-lock.json" ]; then
    npm ci
else
    npm install
fi
cd ..

echo -e "${YELLOW}Installing backend dependencies...${NC}"
cd backend
if [ -f "package-lock.json" ]; then
    npm ci
else
    npm install
fi
cd ..

# Create development environment file
echo -e "${YELLOW}Creating development environment file...${NC}"
if [ ! -f ".env.dev" ]; then
    cat > .env.dev << EOF
# Development Environment Configuration
NODE_ENV=development

# Database Configuration (Local Development)
DB_HOST=localhost
DB_USER=root
DB_PASS=password
DB_NAME=jobboard_dev

# Application Ports
FRONTEND_PORT=3000
BACKEND_PORT=3001

# Other Configuration
DEBUG=true
LOG_LEVEL=debug
EOF
    echo -e "${GREEN}✓ Created .env.dev file${NC}"
else
    echo -e "${YELLOW}⚠ .env.dev file already exists${NC}"
fi

# Create Docker Compose override for development
echo -e "${YELLOW}Creating Docker Compose development configuration...${NC}"
cat > docker-compose.dev.yml << EOF
version: '3.8'

services:
  # Development Database
  mysql-dev:
    image: mysql:8.0
    container_name: jobboard-mysql-dev
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: jobboard_dev
      MYSQL_USER: dev_user
      MYSQL_PASSWORD: dev_password
    ports:
      - "3307:3306"
    volumes:
      - mysql_dev_data:/var/lib/mysql
      - ./scripts/setup-db.sql:/docker-entrypoint-initdb.d/setup-db.sql
    networks:
      - jobboard-dev-network

  # Backend Development
  backend-dev:
    build:
      context: .
      dockerfile: docker/Dockerfile.backend
    container_name: jobboard-backend-dev
    restart: unless-stopped
    environment:
      DB_HOST: mysql-dev
      DB_USER: dev_user
      DB_PASS: dev_password
      DB_NAME: jobboard_dev
      PORT: 3001
      NODE_ENV: development
    ports:
      - "3001:3001"
    volumes:
      - ./backend:/app
      - /app/node_modules
    depends_on:
      mysql-dev:
        condition: service_healthy
    networks:
      - jobboard-dev-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Frontend Development
  frontend-dev:
    build:
      context: .
      dockerfile: docker/Dockerfile.frontend
    container_name: jobboard-frontend-dev
    restart: unless-stopped
    ports:
      - "3000:80"
    volumes:
      - ./frontend/src:/usr/share/nginx/html/src
      - ./frontend/public:/usr/share/nginx/html/public
    depends_on:
      - backend-dev
    networks:
      - jobboard-dev-network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  mysql_dev_data:
    driver: local

networks:
  jobboard-dev-network:
    driver: bridge
EOF

echo -e "${GREEN}✓ Created docker-compose.dev.yml${NC}"

# Function to start development environment
start_dev() {
    echo -e "${YELLOW}Starting development environment...${NC}"
    
    # Start Docker containers
    if command -v "docker-compose" &> /dev/null; then
        docker-compose -f docker/docker-compose.yml up -d
    else
        docker compose -f docker/docker-compose.yml up -d
    fi
    
    echo -e "${GREEN}✓ Development environment started${NC}"
    echo ""
    echo "Services available at:"
    echo "  Frontend: http://localhost:3000"
    echo "  Backend API: http://localhost:3001"
    echo "  Database: localhost:3307"
    echo ""
    echo "To view logs:"
    echo "  docker-compose -f docker/docker-compose.yml logs -f"
    echo ""
    echo "To stop development environment:"
    echo "  docker-compose -f docker/docker-compose.yml down"
}

# Function to setup local development
setup_local() {
    echo -e "${YELLOW}Setting up local development environment...${NC}"
    
    # Start database
    echo -e "${YELLOW}Starting MySQL database...${NC}"
    docker run -d \
        --name jobboard-mysql-dev \
        -e MYSQL_ROOT_PASSWORD=password \
        -e MYSQL_DATABASE=jobboard_dev \
        -e MYSQL_USER=dev_user \
        -e MYSQL_PASSWORD=dev_password \
        -p 3307:3306 \
        -v mysql_dev_data:/var/lib/mysql \
        mysql:8.0
    
    # Wait for database to be ready
    echo "Waiting for database to be ready..."
    sleep 20
    
    # Setup database schema
    echo -e "${YELLOW}Setting up database schema...${NC}"
    docker exec jobboard-mysql-dev mysql -u root -ppassword jobboard_dev < scripts/setup-db.sql
    
    echo -e "${GREEN}✓ Local development environment ready${NC}"
    echo ""
    echo "Database: mysql://dev_user:dev_password@localhost:3307/jobboard_dev"
}

# Show menu
echo ""
echo "What would you like to do?"
echo "1) Start full development environment (Docker)"
echo "2) Setup local development environment"
echo "3) Install dependencies only"
echo ""
read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        start_dev
        ;;
    2)
        setup_local
        ;;
    3)
        echo -e "${GREEN}Dependencies installed successfully!${NC}"
        echo ""
        echo "To start the development servers:"
        echo "  Frontend: cd frontend && npm start"
        echo "  Backend: cd backend && npm run dev"
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}Development setup completed!${NC}"