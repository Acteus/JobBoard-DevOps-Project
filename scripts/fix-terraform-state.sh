#!/bin/bash
set -e

# =============================================================================
# Terraform State Cleanup and Fix Script
# =============================================================================
# This script resolves common Terraform state synchronization issues
# by cleaning up orphaned resources and importing existing ones

echo "=============================================="
echo "Terraform State Cleanup and Fix Script"
echo "=============================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running in correct directory
if [ ! -d "terraform" ]; then
    echo -e "${RED}❌ Error: terraform directory not found${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Check AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ Error: AWS CLI not configured${NC}"
    echo "Please configure AWS credentials first"
    exit 1
fi

echo -e "${GREEN}✅ AWS credentials verified${NC}"

# Get project name
PROJECT_NAME="${PROJECT_NAME:-jobboard}"

echo ""
echo "=== Step 1: Analyzing Current AWS Resources ==="
echo ""

# Check EIP usage
echo "Checking EIP usage..."
EIP_COUNT=$(aws ec2 describe-addresses --query 'Addresses | length' --output text 2>/dev/null || echo "0")
echo -e "Current EIP count: ${YELLOW}${EIP_COUNT}/5${NC}"

if [ "$EIP_COUNT" -ge 5 ]; then
    echo -e "${RED}⚠️ WARNING: EIP limit reached!${NC}"
    echo ""
    echo "Listing all EIPs:"
    aws ec2 describe-addresses --query 'Addresses[*].[PublicIp,AllocationId,AssociationId,Tags[?Key==`Name`].Value|[0]]' --output table
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "1. Release unused EIPs manually from AWS Console"
    echo "2. Request EIP limit increase from AWS"
    echo "3. Modify Terraform to use fewer NAT Gateways (reduce from 2 to 1)"
    echo ""
    read -p "Do you want to continue and attempt cleanup? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "=== Step 2: Checking for Orphaned Resources ==="
echo ""

# Check for existing resources
echo "Checking for existing CloudWatch Log Group..."
LOG_GROUP=$(aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/${PROJECT_NAME}" --query 'logGroups[0].logGroupName' --output text 2>/dev/null || echo "")
if [ ! -z "$LOG_GROUP" ] && [ "$LOG_GROUP" != "None" ]; then
    echo -e "${YELLOW}⚠️ Found existing log group: $LOG_GROUP${NC}"
fi

echo "Checking for existing IAM Instance Profile..."
INSTANCE_PROFILE=$(aws iam get-instance-profile --instance-profile-name "${PROJECT_NAME}-ec2-profile" --query 'InstanceProfile.InstanceProfileName' --output text 2>/dev/null || echo "")
if [ ! -z "$INSTANCE_PROFILE" ] && [ "$INSTANCE_PROFILE" != "None" ]; then
    echo -e "${YELLOW}⚠️ Found existing instance profile: $INSTANCE_PROFILE${NC}"
fi

echo "Checking for subnets with dependencies..."
SUBNETS=$(aws ec2 describe-subnets --filters "Name=tag:Project,Values=${PROJECT_NAME}" --query 'Subnets[*].[SubnetId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' --output text 2>/dev/null || echo "")
if [ ! -z "$SUBNETS" ]; then
    echo -e "${YELLOW}⚠️ Found existing subnets:${NC}"
    echo "$SUBNETS"
fi

echo ""
echo "=== Step 3: Solution Options ==="
echo ""
echo "Choose an action:"
echo ""
echo "1) IMPORT existing resources into Terraform state (recommended)"
echo "   - Imports CloudWatch Log Group, IAM Profile, and other existing resources"
echo "   - Preserves existing infrastructure"
echo ""
echo "2) CLEAN UP and start fresh (destructive)"
echo "   - Manually delete all resources"
echo "   - WARNING: This will destroy RDS database and all data!"
echo ""
echo "3) REDUCE NAT Gateways (cost optimization)"
echo "   - Modifies Terraform to use only 1 NAT Gateway instead of 2"
echo "   - Reduces EIP usage from 2 to 1"
echo ""
echo "4) VIEW detailed resource information only"
echo "   - Lists all resources without making changes"
echo ""
echo "5) EXIT without changes"
echo ""

read -p "Enter your choice (1-5): " -n 1 -r
echo ""

case $REPLY in
    1)
        echo ""
        echo "=== Importing Existing Resources into Terraform State ==="
        echo ""
        
        cd terraform
        
        # Initialize Terraform if needed
        if [ ! -d ".terraform" ]; then
            echo "Initializing Terraform..."
            terraform init
        fi
        
        # Check if DB password is provided
        if [ -z "$DB_PASSWORD" ]; then
            read -sp "Enter DB Password: " DB_PASSWORD
            echo ""
        fi
        
        # Import CloudWatch Log Group if it exists
        if [ ! -z "$LOG_GROUP" ] && [ "$LOG_GROUP" != "None" ]; then
            echo "Importing CloudWatch Log Group..."
            if terraform state show aws_cloudwatch_log_group.app &> /dev/null; then
                echo "✅ Log group already in state"
            else
                terraform import -var="db_password=$DB_PASSWORD" aws_cloudwatch_log_group.app "$LOG_GROUP" || echo "⚠️ Import failed (may already be imported)"
            fi
        fi
        
        # Import IAM Instance Profile if it exists
        if [ ! -z "$INSTANCE_PROFILE" ] && [ "$INSTANCE_PROFILE" != "None" ]; then
            echo "Importing IAM Instance Profile..."
            if terraform state show aws_iam_instance_profile.ec2_profile &> /dev/null; then
                echo "✅ Instance profile already in state"
            else
                terraform import -var="db_password=$DB_PASSWORD" aws_iam_instance_profile.ec2_profile "$INSTANCE_PROFILE" || echo "⚠️ Import failed (may already be imported)"
            fi
        fi
        
        # Import IAM Role
        IAM_ROLE="${PROJECT_NAME}-ec2-role"
        if aws iam get-role --role-name "$IAM_ROLE" &> /dev/null; then
            echo "Importing IAM Role..."
            if terraform state show aws_iam_role.ec2_role &> /dev/null; then
                echo "✅ IAM role already in state"
            else
                terraform import -var="db_password=$DB_PASSWORD" aws_iam_role.ec2_role "$IAM_ROLE" || echo "⚠️ Import failed"
            fi
        fi
        
        echo ""
        echo -e "${GREEN}✅ Import process completed${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Run 'terraform plan' to verify state"
        echo "2. Address any remaining resource conflicts"
        echo "3. Consider option 3 to reduce NAT gateways if EIP limit is an issue"
        ;;
        
    2)
        echo ""
        echo -e "${RED}⚠️ WARNING: This will DELETE all resources!${NC}"
        echo ""
        read -p "Are you ABSOLUTELY sure? Type 'DELETE' to confirm: " CONFIRM
        if [ "$CONFIRM" != "DELETE" ]; then
            echo "Cancelled."
            exit 0
        fi
        
        echo ""
        echo "=== Cleaning Up Resources ==="
        echo ""
        
        # Delete RDS instances first (this takes time)
        echo "Checking for RDS instances..."
        RDS_INSTANCES=$(aws rds describe-db-instances --query "DBInstances[?contains(DBInstanceIdentifier, '${PROJECT_NAME}')].DBInstanceIdentifier" --output text)
        if [ ! -z "$RDS_INSTANCES" ]; then
            for instance in $RDS_INSTANCES; do
                echo "Deleting RDS instance: $instance (this may take 10-15 minutes)..."
                aws rds delete-db-instance \
                    --db-instance-identifier "$instance" \
                    --skip-final-snapshot \
                    --delete-automated-backups 2>/dev/null || echo "⚠️ Failed to delete RDS instance"
            done
            
            echo "Waiting for RDS instances to be deleted..."
            sleep 60
        fi
        
        # Delete NAT Gateways (to free up EIPs)
        echo "Deleting NAT Gateways..."
        NAT_GATEWAYS=$(aws ec2 describe-nat-gateways --filter "Name=tag:Project,Values=${PROJECT_NAME}" "Name=state,Values=available" --query 'NatGateways[*].NatGatewayId' --output text)
        if [ ! -z "$NAT_GATEWAYS" ]; then
            for nat in $NAT_GATEWAYS; do
                echo "Deleting NAT Gateway: $nat"
                aws ec2 delete-nat-gateway --nat-gateway-id "$nat" || echo "⚠️ Failed to delete NAT gateway"
            done
            echo "Waiting for NAT Gateways to be deleted (this takes a few minutes)..."
            sleep 120
        fi
        
        # Release EIPs associated with project
        echo "Releasing Elastic IPs..."
        EIP_ALLOCS=$(aws ec2 describe-addresses --filters "Name=tag:Project,Values=${PROJECT_NAME}" --query 'Addresses[*].AllocationId' --output text)
        if [ ! -z "$EIP_ALLOCS" ]; then
            for eip in $EIP_ALLOCS; do
                echo "Releasing EIP: $eip"
                aws ec2 release-address --allocation-id "$eip" 2>/dev/null || echo "⚠️ Failed to release EIP (may be in use)"
            done
        fi
        
        # Delete CloudWatch Log Group
        if [ ! -z "$LOG_GROUP" ]; then
            echo "Deleting CloudWatch Log Group: $LOG_GROUP"
            aws logs delete-log-group --log-group-name "$LOG_GROUP" 2>/dev/null || echo "⚠️ Failed to delete log group"
        fi
        
        # Delete IAM resources
        if [ ! -z "$INSTANCE_PROFILE" ]; then
            echo "Removing role from instance profile..."
            aws iam remove-role-from-instance-profile \
                --instance-profile-name "$INSTANCE_PROFILE" \
                --role-name "${PROJECT_NAME}-ec2-role" 2>/dev/null || echo "⚠️ Role already removed or doesn't exist"
            
            echo "Deleting instance profile..."
            aws iam delete-instance-profile --instance-profile-name "$INSTANCE_PROFILE" 2>/dev/null || echo "⚠️ Failed to delete instance profile"
        fi
        
        echo ""
        echo -e "${GREEN}✅ Cleanup completed${NC}"
        echo "You can now run Terraform fresh"
        ;;
        
    3)
        echo ""
        echo "=== Reducing NAT Gateways from 2 to 1 ==="
        echo ""
        echo "This will modify your Terraform configuration to:"
        echo "- Use only 1 NAT Gateway instead of 2"
        echo "- Reduce EIP usage from 2 to 1"
        echo "- Both private subnets will share the same NAT Gateway"
        echo ""
        read -p "Continue? (y/n): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
        
        echo "This option will be implemented in the next step..."
        echo "For now, manually edit terraform/main.tf:"
        echo ""
        echo "Change line 77 from:"
        echo "  count = length(var.public_subnet_cidrs)"
        echo "To:"
        echo "  count = 1"
        echo ""
        echo "And change line 86 from:"
        echo "  count = length(var.public_subnet_cidrs)"
        echo "To:"
        echo "  count = 1"
        echo ""
        echo "And change line 117 from:"
        echo "  nat_gateway_id = aws_nat_gateway.main[count.index].id"
        echo "To:"
        echo "  nat_gateway_id = aws_nat_gateway.main[0].id"
        ;;
        
    4)
        echo ""
        echo "=== Detailed Resource Information ==="
        echo ""
        
        echo "--- VPCs ---"
        aws ec2 describe-vpcs --filters "Name=tag:Project,Values=${PROJECT_NAME}" --output table 2>/dev/null || echo "None found"
        
        echo ""
        echo "--- Subnets ---"
        aws ec2 describe-subnets --filters "Name=tag:Project,Values=${PROJECT_NAME}" --output table 2>/dev/null || echo "None found"
        
        echo ""
        echo "--- NAT Gateways ---"
        aws ec2 describe-nat-gateways --filter "Name=tag:Project,Values=${PROJECT_NAME}" --output table 2>/dev/null || echo "None found"
        
        echo ""
        echo "--- Elastic IPs ---"
        aws ec2 describe-addresses --output table 2>/dev/null || echo "None found"
        
        echo ""
        echo "--- RDS Instances ---"
        aws rds describe-db-instances --query "DBInstances[?contains(DBInstanceIdentifier, '${PROJECT_NAME}')]" --output table 2>/dev/null || echo "None found"
        
        echo ""
        echo "--- Security Groups ---"
        aws ec2 describe-security-groups --filters "Name=tag:Project,Values=${PROJECT_NAME}" --output table 2>/dev/null || echo "None found"
        ;;
        
    5)
        echo "Exiting without changes."
        exit 0
        ;;
        
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "=== Script Complete ==="
echo ""

