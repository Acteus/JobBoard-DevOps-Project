#!/bin/bash

# Terraform Clean Slate Script
# This script ensures a completely clean Terraform environment for fresh deployment

# set -e  # Exit on any error - Disabled to handle AWS CLI errors gracefully

echo "🧹 Starting Terraform Clean Slate Process..."
echo "============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 1. Clean local Terraform state
echo ""
echo "📁 Cleaning local Terraform state..."
cd terraform

# Remove state files
echo "   Removing state files..."
rm -f terraform.tfstate terraform.tfstate.backup *.tfstate* 2>/dev/null
print_status "State files removed"

# Check for sensitive files
if [ -f "terraform.tfvars" ]; then
    print_warning "Found terraform.tfvars file - this should not be committed!"
    echo "   Consider removing: rm terraform/terraform.tfvars"
else
    print_status "No sensitive terraform.tfvars file found"
fi

# Verify template exists
if [ -f "terraform.tfvars.example" ]; then
    print_status "terraform.tfvars.example template available"
else
    print_error "terraform.tfvars.example template not found!"
fi

# Get AWS region from terraform config
AWS_REGION=$(grep 'aws_region' terraform.tfvars | cut -d'"' -f2)
if [ -z "$AWS_REGION" ]; then
    AWS_REGION="us-east-1"  # Default fallback
fi

echo ""
echo "☁️  Cleaning AWS resources in region: $AWS_REGION"
echo "   Note: This requires AWS CLI to be configured"

# RDS Instance
echo "   Checking RDS Instance..."
if aws rds describe-db-instances --db-instance-identifier jobboard-db-dev --region $AWS_REGION --query 'DBInstances' --output text 2>/dev/null | grep -q jobboard; then
    echo "   Deleting RDS Instance..."
    if aws rds delete-db-instance --db-instance-identifier jobboard-db-dev --skip-final-snapshot --region $AWS_REGION 2>/dev/null; then
        print_status "RDS Instance deleted"
        # Wait for deletion to complete
        echo "   Waiting for RDS deletion..."
        aws rds wait db-instance-deleted --db-instance-identifier jobboard-db-dev --region $AWS_REGION 2>/dev/null || true
    else
        print_error "Failed to delete RDS Instance"
    fi
else
    print_status "RDS Instance not found (already clean)"
fi

# DB Subnet Group
echo "   Checking DB Subnet Group..."
if aws rds describe-db-subnet-groups --db-subnet-group-name jobboard-db-subnet-group --region $AWS_REGION --query 'DBSubnetGroups' --output text 2>/dev/null | grep -q jobboard; then
    echo "   Deleting DB Subnet Group..."
    if aws rds delete-db-subnet-group --db-subnet-group-name jobboard-db-subnet-group --region $AWS_REGION 2>/dev/null; then
        print_status "DB Subnet Group deleted"
    else
        print_error "Failed to delete DB Subnet Group (may still be in use)"
    fi
else
    print_status "DB Subnet Group not found (already clean)"
fi

# CloudWatch Log Group
echo "   Checking CloudWatch Log Group..."
if aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/jobboard-app" --region $AWS_REGION --query 'logGroups' --output text 2>/dev/null | grep -q jobboard-app; then
    echo "   Deleting CloudWatch Log Group..."
    if aws logs delete-log-group --log-group-name "/aws/ec2/jobboard-app" --region $AWS_REGION 2>/dev/null; then
        print_status "CloudWatch Log Group deleted"
    else
        print_error "Failed to delete CloudWatch Log Group"
    fi
else
    print_status "CloudWatch Log Group not found (already clean)"
fi

# IAM Role (complex cleanup)
echo "   Checking IAM Role..."
if aws iam get-role --role-name jobboard-ec2-role --region $AWS_REGION --query 'Role' --output text 2>/dev/null | grep -q jobboard; then
    echo "   Cleaning up IAM Role (this may take a few steps)..."

    # Find instance profile
    INSTANCE_PROFILE=$(aws iam list-instance-profiles --region $AWS_REGION --query 'InstanceProfiles[?contains(InstanceProfileName, \`jobboard\`)].InstanceProfileName' --output text 2>/dev/null || echo "")

    if [ ! -z "$INSTANCE_PROFILE" ] && [ "$INSTANCE_PROFILE" != "None" ]; then
        echo "   Removing role from instance profile..."
        if aws iam remove-role-from-instance-profile --instance-profile-name "$INSTANCE_PROFILE" --role-name jobboard-ec2-role --region $AWS_REGION 2>/dev/null; then
            print_status "Role removed from instance profile"
        else
            print_warning "Failed to remove role from instance profile (may not be attached)"
        fi

        echo "   Deleting instance profile..."
        if aws iam delete-instance-profile --instance-profile-name "$INSTANCE_PROFILE" --region $AWS_REGION 2>/dev/null; then
            print_status "Instance profile deleted"
        else
            print_warning "Failed to delete instance profile (may not exist)"
        fi
    fi

    # Detach policies
    for policy in $(aws iam list-attached-role-policies --role-name jobboard-ec2-role --region $AWS_REGION --query 'AttachedPolicies[*].PolicyArn' --output text 2>/dev/null || echo ""); do
        if [ ! -z "$policy" ] && [ "$policy" != "None" ]; then
            echo "   Detaching policy: $policy"
            if aws iam detach-role-policy --role-name jobboard-ec2-role --policy-arn "$policy" --region $AWS_REGION 2>/dev/null; then
                print_status "Policy detached: $policy"
            else
                print_warning "Failed to detach policy: $policy (may not be attached)"
            fi
        fi
    done

    # Delete role
    if aws iam delete-role --role-name jobboard-ec2-role --region $AWS_REGION 2>/dev/null; then
        print_status "IAM Role deleted"
    else
        print_warning "Failed to delete IAM Role (may not exist)"
    fi
else
    print_status "IAM Role not found (already clean)"
fi

# EC2 Instance
echo "   Checking EC2 Instance..."
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=jobboard-app-server" "Name=instance-state-name,Values=running,stopped,pending,stopping" --region $AWS_REGION --query 'Reservations[*].Instances[*].InstanceId' --output text 2>/dev/null || echo "")
if [ ! -z "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "None" ]; then
    echo "   Terminating EC2 Instance: $INSTANCE_ID"
    if aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" --region $AWS_REGION 2>/dev/null; then
        print_status "EC2 Instance terminated"
        # Wait for termination
        echo "   Waiting for EC2 termination..."
        aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID" --region $AWS_REGION 2>/dev/null || true
    else
        print_error "Failed to terminate EC2 Instance"
    fi
else
    print_status "EC2 Instance not found (already clean)"
fi

# Load Balancer
echo "   Checking Load Balancer..."
if LB_ARN=$(aws elbv2 describe-load-balancers --names jobboard-alb --region $AWS_REGION --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || echo ""); then
    if [ ! -z "$LB_ARN" ] && [ "$LB_ARN" != "None" ]; then
        # Delete listeners first
        echo "   Deleting Load Balancer Listeners..."
        LISTENER_ARNS=$(aws elbv2 describe-listeners --load-balancer-arn "$LB_ARN" --region $AWS_REGION --query 'Listeners[*].ListenerArn' --output text 2>/dev/null || echo "")
        for listener_arn in $LISTENER_ARNS; do
            if [ ! -z "$listener_arn" ] && [ "$listener_arn" != "None" ]; then
                aws elbv2 delete-listener --listener-arn "$listener_arn" --region $AWS_REGION 2>/dev/null || true
            fi
        done
        print_status "Listeners deleted"

        echo "   Deleting Load Balancer..."
        if aws elbv2 delete-load-balancer --load-balancer-arn "$LB_ARN" --region $AWS_REGION 2>/dev/null; then
            print_status "Load Balancer deleted"
        else
            print_warning "Failed to delete Load Balancer (may still be in use)"
        fi
    fi
else
    print_status "Load Balancer not found (already clean)"
fi

# Target Group
echo "   Checking Target Group..."
if TG_ARN=$(aws elbv2 describe-target-groups --names jobboard-app-tg --region $AWS_REGION --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo ""); then
    if [ ! -z "$TG_ARN" ] && [ "$TG_ARN" != "None" ]; then
        echo "   Found Target Group: $TG_ARN"

        # First, try to deregister all targets
        echo "   Deregistering targets from Target Group..."
        for target in $(aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --region $AWS_REGION --query 'TargetHealthDescriptions[*].Target.Id' --output text 2>/dev/null || echo ""); do
            if [ ! -z "$target" ] && [ "$target" != "None" ]; then
                echo "   Deregistering target: $target"
                aws elbv2 deregister-targets --target-group-arn "$TG_ARN" --targets Id="$target" --region $AWS_REGION 2>/dev/null || true
            fi
        done

        # Wait a moment for deregistration to complete
        sleep 2

        echo "   Deleting Target Group..."
        if aws elbv2 delete-target-group --target-group-arn "$TG_ARN" --region $AWS_REGION 2>/dev/null; then
            print_status "Target Group deleted"
        else
            print_warning "Failed to delete Target Group (may be in use by Load Balancer)"
        fi
    fi
else
    print_status "Target Group not found (already clean)"
fi

# 3. Final verification
echo ""
echo "🔍 Final Verification..."
echo "======================"

# Local checks
echo "Local Environment:"
echo "   State files: $(ls terraform.tfstate* 2>/dev/null | wc -l) found"
echo "   Sensitive files: $(ls terraform.tfvars 2>/dev/null | wc -l) found"
echo "   Template file: $(ls terraform.tfvars.example 2>/dev/null | wc -l) found"

# AWS checks
echo ""
echo "AWS Environment:"
CONFLICTS=0

if aws rds describe-db-instances --db-instance-identifier jobboard-db-dev --region $AWS_REGION 2>/dev/null | grep -q jobboard; then
    echo "   ❌ RDS Instance: Found"
    ((CONFLICTS++))
else
    echo "   ✅ RDS Instance: Clean"
fi

if aws ec2 describe-instances --filters "Name=tag:Name,Values=jobboard-app-server" "Name=instance-state-name,Values=running,stopped,pending,stopping" --region $AWS_REGION --query 'Reservations' --output text 2>/dev/null | grep -q i-; then
    echo "   ❌ EC2 Instance: Found"
    ((CONFLICTS++))
else
    echo "   ✅ EC2 Instance: Clean"
fi

if aws rds describe-db-subnet-groups --db-subnet-group-name jobboard-db-subnet-group --region $AWS_REGION 2>/dev/null | grep -q jobboard; then
    echo "   ❌ DB Subnet Group: Found"
    ((CONFLICTS++))
else
    echo "   ✅ DB Subnet Group: Clean"
fi

if aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/jobboard-app" --region $AWS_REGION 2>/dev/null | grep -q jobboard-app; then
    echo "   ❌ CloudWatch Log Group: Found"
    ((CONFLICTS++))
else
    echo "   ✅ CloudWatch Log Group: Clean"
fi

if aws iam get-role --role-name jobboard-ec2-role --region $AWS_REGION 2>/dev/null | grep -q jobboard; then
    echo "   ❌ IAM Role: Found"
    ((CONFLICTS++))
else
    echo "   ✅ IAM Role: Clean"
fi

if aws elbv2 describe-load-balancers --names jobboard-alb --region $AWS_REGION 2>/dev/null | grep -q jobboard; then
    echo "   ❌ Load Balancer: Found"
    ((CONFLICTS++))
else
    echo "   ✅ Load Balancer: Clean"
fi

if aws elbv2 describe-target-groups --names jobboard-app-tg --region $AWS_REGION 2>/dev/null | grep -q jobboard; then
    echo "   ❌ Target Group: Found"
    ((CONFLICTS++))
else
    echo "   ✅ Target Group: Clean"
fi

echo ""
if [ $CONFLICTS -eq 0 ]; then
    print_status "CLEAN SLATE VERIFIED! Ready for deployment."
    echo ""
    echo "🚀 Next steps:"
    echo "   1. Ensure your GitHub Secrets are set correctly"
    echo "   2. Update DB_PASSWORD to use only allowed characters"
    echo "   3. Push to trigger GitHub Actions deployment"
else
    print_error "Found $CONFLICTS conflicting resources. Run this script again."
fi

echo ""
echo "============================================="
echo "Clean slate process completed!"