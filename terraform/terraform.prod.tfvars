# Production Terraform Variables for JobBoard Project
# This file contains production-specific configuration values

# AWS Configuration
aws_region = "us-east-1"
project_name = "jobboard"
environment = "prod"

# Database Configuration
db_username = "jobboard_user"
# Note: db_password should be set via GitHub secrets for production

# EC2 Configuration
instance_type = "t2.small"  # Slightly larger instance for production
key_pair_name = "jobboard-key-prod"

# Network Configuration (using defaults from variables.tf)
# vpc_cidr = "10.0.0.0/16"
# public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
# private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
# availability_zones = ["us-east-1a", "us-east-1b"]

# RDS Configuration - Production settings
rds_instance_class = "db.t3.small"  # Larger instance for production
rds_allocated_storage = 50  # More storage for production
backup_retention_period = 14  # Longer backup retention
deletion_protection = true  # Protect against accidental deletion
multi_az = true  # Multi-AZ for high availability
auto_minor_version_upgrade = true

# Monitoring Configuration
cloudwatch_retention = 90  # Longer log retention for production
enable_monitoring = true

# S3 Configuration (optional)
# s3_bucket_name = "your-jobboard-static-assets-bucket"

# SSL/TLS Configuration (recommended for production)
# certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
# domain_name = "your-domain.com"