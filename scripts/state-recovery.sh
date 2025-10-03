#!/bin/bash

# State Recovery Script for Terraform
# This script helps recover Terraform state when resources exist but state is lost

set -e

echo "🔄 Starting Terraform State Recovery..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log with colors
log_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the terraform directory
if [ ! -f "main.tf" ]; then
    log_error "main.tf not found. Please run this script from the terraform directory."
    exit 1
fi

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    log_info "Initializing Terraform..."
    terraform init
fi

# Function to import resource if it exists
import_resource() {
    local resource_type="$1"
    local resource_name="$2"
    local filter_value="$3"
    local extra_param="$4"

    log_info "Checking for existing $resource_type: $resource_name..."

    case "$resource_type" in
        "vpc")
            RESOURCE_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values="$filter_value" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "")
            ;;
        "subnet")
            if [ ! -z "$extra_param" ]; then
                # Try CIDR first
                RESOURCE_ID=$(aws ec2 describe-subnets --filters Name=cidr-block,Values="$extra_param" --query 'Subnets[0].SubnetId' --output text 2>/dev/null || echo "")
            fi
            # Fallback to tag-based search
            if [ -z "$RESOURCE_ID" ] || [ "$RESOURCE_ID" = "None" ]; then
                RESOURCE_ID=$(aws ec2 describe-subnets --filters Name=tag:Name,Values="$filter_value" --query 'Subnets[0].SubnetId' --output text 2>/dev/null || echo "")
            fi
            ;;
        "security_group")
            RESOURCE_ID=$(aws ec2 describe-security-groups --filters Name=tag:Name,Values="$filter_value" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "")
            ;;
        "internet_gateway")
            if [ ! -z "$extra_param" ]; then
                # Check if VPC already has an internet gateway attached
                VPC_ID="$extra_param"
                RESOURCE_ID=$(aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values="$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null || echo "")
                log_info "Found existing internet gateway $RESOURCE_ID attached to VPC $VPC_ID"
            fi
            ;;
        "route_table_association")
            if [ ! -z "$extra_param" ] && [ ! -z "$filter_value" ]; then
                SUBNET_ID="$extra_param"
                ROUTE_TABLE_ID="$filter_value"
                ASSOCIATION_ID=$(aws ec2 describe-route-tables --route-table-ids "$ROUTE_TABLE_ID" --query "RouteTables[0].Associations[?SubnetId=='$SUBNET_ID'].RouteTableAssociationId" --output text 2>/dev/null || echo "")
                if [ ! -z "$ASSOCIATION_ID" ] && [ "$ASSOCIATION_ID" != "None" ]; then
                    RESOURCE_ID="$SUBNET_ID/$ROUTE_TABLE_ID"
                    log_info "Found existing route table association between subnet $SUBNET_ID and route table $ROUTE_TABLE_ID"
                fi
            fi
            ;;
        "iam_role")
            RESOURCE_ID=$(aws iam get-role --role-name "$filter_value" --query 'Role.RoleName' --output text 2>/dev/null || echo "")
            ;;
        "log_group")
            # For log groups, we need to check by name pattern
            LOG_GROUP_NAME="/aws/ec2/jobboard-app"
            RESOURCE_ID=$(aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP_NAME" --query 'logGroups[0].logGroupName' --output text 2>/dev/null || echo "")
            ;;
        "instance_profile")
            RESOURCE_ID=$(aws iam get-instance-profile --instance-profile-name "$filter_value" --query 'InstanceProfile.InstanceProfileName' --output text 2>/dev/null || echo "")
            ;;
        "load_balancer")
            RESOURCE_ID=$(aws elbv2 describe-load-balancers --names "$filter_value" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || echo "")
            ;;
        "target_group")
            RESOURCE_ID=$(aws elbv2 describe-target-groups --names "$filter_value" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo "")
            ;;
        *)
            log_warn "Unknown resource type: $resource_type"
            return
            ;;
    esac

    if [ ! -z "$RESOURCE_ID" ] && [ "$RESOURCE_ID" != "None" ] && [ "$RESOURCE_ID" != "" ]; then
        log_info "Found existing $resource_type: $RESOURCE_ID"
        log_info "Attempting to import $resource_name..."
        if terraform import "$resource_name" "$RESOURCE_ID" 2>/dev/null; then
            log_info "✅ Successfully imported $resource_type: $RESOURCE_ID"
        else
            log_warn "⚠️ Import failed or resource already imported: $resource_name"
        fi
    else
        log_warn "No existing $resource_type found"
    fi
}

# Import resources in dependency order
log_info "Starting resource imports..."

# 1. Import VPC first
import_resource "vpc" "aws_vpc.main" "jobboard-vpc"

# 2. Get VPC ID for dependent resources
VPC_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=jobboard-vpc --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "")

# 3. Import subnets
import_resource "subnet" "aws_subnet.public[0]" "jobboard-public-subnet-1" "10.0.1.0/24"
import_resource "subnet" "aws_subnet.public[1]" "jobboard-public-subnet-2" "10.0.2.0/24"
import_resource "subnet" "aws_subnet.private[0]" "jobboard-private-subnet-1" "10.0.3.0/24"
import_resource "subnet" "aws_subnet.private[1]" "jobboard-private-subnet-2" "10.0.4.0/24"

# 4. Import security groups
import_resource "security_group" "aws_security_group.web" "jobboard-web-sg"
import_resource "security_group" "aws_security_group.app" "jobboard-app-sg"
import_resource "security_group" "aws_security_group.db" "jobboard-db-sg"

# 5. Import internet gateway
import_resource "internet_gateway" "aws_internet_gateway.main" "jobboard-igw" "$VPC_ID"

# 6. Import route table associations
PUBLIC_RT_ID=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=jobboard-public-rt --query 'RouteTables[0].RouteTableId' --output text 2>/dev/null || echo "")
PRIVATE_RT_1_ID=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=jobboard-private-rt-1 --query 'RouteTables[0].RouteTableId' --output text 2>/dev/null || echo "")
PRIVATE_RT_2_ID=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=jobboard-private-rt-2 --query 'RouteTables[0].RouteTableId' --output text 2>/dev/null || echo "")

import_resource "route_table_association" "aws_route_table_association.public[0]" "$PUBLIC_RT_ID" "$(aws ec2 describe-subnets --filters Name=tag:Name,Values=jobboard-public-subnet-1 --query 'Subnets[0].SubnetId' --output text 2>/dev/null || echo "")"
import_resource "route_table_association" "aws_route_table_association.public[1]" "$PUBLIC_RT_ID" "$(aws ec2 describe-subnets --filters Name=tag:Name,Values=jobboard-public-subnet-2 --query 'Subnets[0].SubnetId' --output text 2>/dev/null || echo "")"
import_resource "route_table_association" "aws_route_table_association.private[0]" "$PRIVATE_RT_1_ID" "$(aws ec2 describe-subnets --filters Name=tag:Name,Values=jobboard-private-subnet-1 --query 'Subnets[0].SubnetId' --output text 2>/dev/null || echo "")"
import_resource "route_table_association" "aws_route_table_association.private[1]" "$PRIVATE_RT_2_ID" "$(aws ec2 describe-subnets --filters Name=tag:Name,Values=jobboard-private-subnet-2 --query 'Subnets[0].SubnetId' --output text 2>/dev/null || echo "")"

# 7. Import IAM role
import_resource "iam_role" "aws_iam_role.ec2_role" "jobboard-ec2-role"

# 8. Import instance profile
import_resource "instance_profile" "aws_iam_instance_profile.ec2_profile" "jobboard-ec2-profile"

# 9. Import CloudWatch log group
import_resource "log_group" "aws_cloudwatch_log_group.app" "jobboard-app"

# 10. Import load balancer and target group (production only)
import_resource "load_balancer" "aws_lb.app[0]" "jobboard-alb"
import_resource "target_group" "aws_lb_target_group.app[0]" "jobboard-app-tg"

log_info "State recovery completed!"
log_info "You can now run 'terraform plan' to see the current state."