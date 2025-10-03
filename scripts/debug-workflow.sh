#!/bin/bash

# GitHub Actions Workflow Debug Script
# This script helps debug issues with the CI/CD pipeline

set -e

echo "🔍 GitHub Actions Workflow Debug Tool"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "🔐 Checking GitHub Secrets..."
echo "============================"

# Check if secrets are available as environment variables
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    print_error "AWS_ACCESS_KEY_ID environment variable not set"
    echo "Make sure to set your GitHub secrets properly"
else
    print_success "AWS_ACCESS_KEY_ID is set"
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    print_error "AWS_SECRET_ACCESS_KEY environment variable not set"
else
    print_success "AWS_SECRET_ACCESS_KEY is set"
fi

if [ -z "$DB_PASSWORD" ]; then
    print_error "DB_PASSWORD environment variable not set"
else
    print_success "DB_PASSWORD is set"
fi

echo ""
echo "🌐 Testing AWS Connectivity..."
echo "=============================="

# Test AWS CLI configuration
print_info "Testing AWS CLI configuration..."
if aws sts get-caller-identity --region us-east-1 >/dev/null 2>&1; then
    print_success "AWS CLI is configured and can access AWS"
    CALLER_IDENTITY=$(aws sts get-caller-identity --region us-east-1)
    echo "AWS Identity: $CALLER_IDENTITY"
else
    print_error "AWS CLI cannot access AWS"
    echo "Possible issues:"
    echo "  • AWS credentials are invalid"
    echo "  • AWS credentials don't have STS permissions"
    echo "  • Network connectivity issues"
    exit 1
fi

echo ""
echo "🏗️  Testing Terraform Configuration..."
echo "==================================="

# Test Terraform initialization
print_info "Testing Terraform initialization..."
cd terraform
if terraform init -input=false -no-color >/dev/null 2>&1; then
    print_success "Terraform initialization successful"
else
    print_error "Terraform initialization failed"
    exit 1
fi

echo ""
echo "🔍 Testing Resource Detection..."
echo "==============================="

# Test VPC detection
print_info "Checking for existing VPC..."
VPC_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=jobboard-vpc --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "")
if [ ! -z "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
    print_warning "Found existing VPC: $VPC_ID"
    echo "This might cause conflicts. Consider running the clean-slate script first."
else
    print_success "No existing VPC found - clean slate"
fi

# Test subnet detection
print_info "Checking for existing subnets..."
for i in 0 1; do
    SUBNET_ID=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=jobboard-public-subnet-$((i+1)) --query 'Subnets[0].SubnetId' --output text 2>/dev/null || echo "")
    if [ ! -z "$SUBNET_ID" ] && [ "$SUBNET_ID" != "None" ]; then
        print_warning "Found existing public subnet $((i+1)): $SUBNET_ID"
    fi

    PRIVATE_SUBNET_ID=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=jobboard-private-subnet-$((i+1)) --query 'Subnets[0].SubnetId' --output text 2>/dev/null || echo "")
    if [ ! -z "$PRIVATE_SUBNET_ID" ] && [ "$PRIVATE_SUBNET_ID" != "None" ]; then
        print_warning "Found existing private subnet $((i+1)): $PRIVATE_SUBNET_ID"
    fi
done

echo ""
echo "🧪 Testing Terraform Plan..."
echo "============================"

# Test terraform plan with variables
print_info "Testing terraform plan with your variables..."
if terraform plan -input=false -no-color \
    -var="db_password=$DB_PASSWORD" \
    -var="aws_region=us-east-1" \
    -var="project_name=jobboard" \
    -var="db_username=jobboard_user" \
    -var="instance_type=t2.micro" \
    -var="key_pair_name=jobboard-key" \
    -var="environment=dev" >/dev/null 2>&1; then
    print_success "Terraform plan executed successfully"
else
    print_error "Terraform plan failed"
    echo ""
    print_info "Running terraform plan with detailed output for debugging..."
    terraform plan -input=false -no-color \
        -var="db_password=$DB_PASSWORD" \
        -var="aws_region=us-east-1" \
        -var="project_name=jobboard" \
        -var="db_username=jobboard_user" \
        -var="instance_type=t2.micro" \
        -var="key_pair_name=jobboard-key" \
        -var="environment=dev"
fi

echo ""
echo "📋 Recommendations:"
echo "=================="

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
    print_warning "Existing resources detected. If you want a clean deployment, run:"
    echo "  ./scripts/clean-slate.sh"
fi

print_success "Debug check completed!"
echo ""
print_info "If the workflow is still failing, check:"
echo "1. GitHub Actions logs for detailed error messages"
echo "2. AWS CloudTrail for any access denied errors"
echo "3. Network connectivity and security groups"