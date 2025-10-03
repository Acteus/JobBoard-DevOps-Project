#!/bin/bash

# JobBoard Cleanup Script
# This script helps clean up resources and reset the environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}JobBoard Cleanup Script${NC}"
echo "======================="

# Function to cleanup Docker resources
cleanup_docker() {
    echo -e "${YELLOW}Cleaning up Docker resources...${NC}"
    
    # Stop and remove containers
    echo "Stopping containers..."
    docker-compose -f docker/docker-compose.yml down 2>/dev/null || true
    
    # Remove images
    echo "Removing Docker images..."
    docker image rm jobboard-backend:latest 2>/dev/null || true
    docker image rm jobboard-frontend:latest 2>/dev/null || true
    docker image rm nginx:alpine 2>/dev/null || true
    docker image rm node:18-alpine 2>/dev/null || true
    
    # Remove volumes
    echo "Removing Docker volumes..."
    docker volume prune -f
    
    echo -e "${GREEN}✓ Docker cleanup completed${NC}"
}

# Function to cleanup Terraform resources
cleanup_terraform() {
    echo -e "${YELLOW}Cleaning up Terraform resources...${NC}"
    
    cd terraform
    
    # Check if Terraform is initialized
    if [ -d ".terraform" ]; then
        echo "Destroying Terraform resources..."
        terraform destroy -auto-approve
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Terraform cleanup completed${NC}"
        else
            echo -e "${RED}✗ Terraform cleanup failed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Terraform not initialized, skipping...${NC}"
    fi
    
    cd ..
}

# Function to cleanup development environment
cleanup_dev() {
    echo -e "${YELLOW}Cleaning up development environment...${NC}"
    
    # Remove development containers
    docker stop jobboard-mysql-dev 2>/dev/null || true
    docker rm jobboard-mysql-dev 2>/dev/null || true
    docker stop jobboard-backend-dev 2>/dev/null || true
    docker rm jobboard-backend-dev 2>/dev/null || true
    docker stop jobboard-frontend-dev 2>/dev/null || true
    docker rm jobboard-frontend-dev 2>/dev/null || true
    
    # Remove development volumes
    docker volume rm mysql_dev_data 2>/dev/null || true
    
    # Remove development files
    rm -f .env.dev
    rm -f docker-compose.dev.yml
    
    echo -e "${GREEN}✓ Development cleanup completed${NC}"
}

# Function to cleanup all
cleanup_all() {
    echo -e "${RED}This will remove ALL resources including production data!${NC}"
    read -p "Are you sure? Type 'yes' to confirm: " -r
    if [[ $REPLY == "yes" ]]; then
        cleanup_docker
        cleanup_terraform
        cleanup_dev
        
        # Remove node_modules
        echo -e "${YELLOW}Removing node_modules...${NC}"
        rm -rf frontend/node_modules
        rm -rf backend/node_modules
        
        # Remove build artifacts
        echo -e "${YELLOW}Removing build artifacts...${NC}"
        rm -rf frontend/build
        rm -rf backend/dist
        
        echo -e "${GREEN}✓ Complete cleanup finished${NC}"
    else
        echo -e "${YELLOW}Cleanup cancelled${NC}"
    fi
}

# Show menu
echo ""
echo "What would you like to clean up?"
echo "1) Docker resources only"
echo "2) Terraform resources only"
echo "3) Development environment only"
echo "4) All resources (WARNING: This removes everything!)"
echo ""
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        cleanup_docker
        ;;
    2)
        cleanup_terraform
        ;;
    3)
        cleanup_dev
        ;;
    4)
        cleanup_all
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}Cleanup completed!${NC}"