# Scripts Documentation

This directory contains utility scripts for setting up, deploying, and managing the JobBoard application.

## Available Scripts

### Database Scripts

#### `setup-db.sql`
SQL script that creates the database schema and inserts sample data.

**Usage:**
```bash
mysql -h [host] -u [username] -p [database] < setup-db.sql
```

#### `setup-db.sh`
Automated script to set up the database using MySQL client.

**Usage:**
```bash
# Set environment variables (optional)
export DB_HOST="localhost"
export DB_USER="root"
export DB_PASS="password"
export DB_NAME="jobboard"

# Run the script
./setup-db.sh
```

### Development Scripts

#### `dev-setup.sh`
Comprehensive script to set up the development environment.

**Features:**
- Installs Node.js dependencies
- Sets up Docker containers for development
- Creates development configuration files
- Provides options for different development setups

**Usage:**
```bash
./dev-setup.sh
```

**Options:**
1. Start full development environment (Docker)
2. Setup local development environment
3. Install dependencies only

### Deployment Scripts

#### `deploy.sh [environment]`
Automated deployment script for different environments.

**Usage:**
```bash
# Deploy to development
./deploy.sh dev

# Deploy to production
./deploy.sh prod
```

**Environment Variables:**
- `AWS_REGION`: AWS region (default: us-east-1)
- `PROJECT_NAME`: Project name (default: jobboard)
- `DB_PASSWORD`: Database password (required)

**Features:**
- Validates prerequisites (Terraform, Docker, AWS CLI)
- Plans and applies Terraform infrastructure
- Builds and deploys Docker containers
- Sets up database schema
- Performs health checks

### Maintenance Scripts

#### `cleanup.sh`
Script to clean up resources and reset environments.

**Usage:**
```bash
./cleanup.sh
```

**Options:**
1. Docker resources only
2. Terraform resources only
3. Development environment only
4. All resources (WARNING: Removes everything!)

## Prerequisites

Before using these scripts, ensure you have:

1. **Docker and Docker Compose** - For containerization
2. **Terraform** - For infrastructure provisioning
3. **AWS CLI** - For cloud operations
4. **Node.js and npm** - For application dependencies
5. **MySQL Client** - For database operations
6. **Git** - For version control

## Environment Configuration

### Development Environment
```bash
# Copy and edit the example environment file
cp ../backend/.env ../backend/.env.local
# Edit .env.local with your local database credentials
```

### Production Environment
```bash
# Use terraform.tfvars for infrastructure variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your production values
```

## Common Workflows

### Local Development Setup
```bash
# 1. Setup development environment
./dev-setup.sh

# 2. Start development servers
cd frontend && npm start    # React dev server
cd ../backend && npm run dev # Backend dev server

# 3. Access the application
# Frontend: http://localhost:3000
# Backend API: http://localhost:3001
```

### Production Deployment
```bash
# 1. Configure AWS credentials
aws configure

# 2. Setup Terraform variables
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 3. Deploy infrastructure and application
cd ..
./deploy.sh prod

# 4. Monitor deployment
# Check AWS Console for resource status
# Monitor CloudWatch for application logs
```

### Database Management
```bash
# Setup database schema
./setup-db.sh

# Or manually run SQL script
mysql -h [host] -u [user] -p [database] < setup-db.sql
```

### Cleanup
```bash
# Clean specific components
./cleanup.sh

# Options:
# 1 - Docker only
# 2 - Terraform only
# 3 - Development environment only
# 4 - Everything (use with caution!)
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   chmod +x scripts/*.sh
   ```

2. **AWS Credentials Not Configured**
   ```bash
   aws configure
   # Or set environment variables
   export AWS_ACCESS_KEY_ID="your-key"
   export AWS_SECRET_ACCESS_KEY="your-secret"
   ```

3. **Port Already in Use**
   ```bash
   # Stop existing containers
   docker-compose -f docker/docker-compose.yml down
   
   # Or change ports in docker-compose.yml
   ```

4. **Node Modules Issues**
   ```bash
   # Clean and reinstall
   rm -rf node_modules package-lock.json
   npm install
   ```

### Getting Help

Each script supports the `-h` or `--help` flag for usage information:

```bash
./setup-db.sh --help
./deploy.sh --help
./dev-setup.sh --help
./cleanup.sh --help
```

## Security Notes

- Never commit `.env` files or Terraform state files to version control
- Use strong, unique passwords for database credentials
- Regularly rotate AWS access keys
- Use AWS IAM roles and policies for production deployments
- Enable encryption for RDS instances and S3 buckets

## Support

For issues or questions about these scripts, please refer to the main project documentation or create an issue in the project repository.