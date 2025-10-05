#!/bin/bash

# Azure JobBoard Setup Script
# This script helps set up your Azure environment for the JobBoard migration

set -e

echo "🔧 Azure JobBoard Setup Script"
echo "=============================="

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed."
    echo "Please install it first:"
    echo "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    exit 1
fi

echo "✅ Azure CLI found"

# Login to Azure
echo "🔐 Checking Azure login status..."
if ! az account show &> /dev/null; then
    echo "Please login to Azure:"
    az login
fi

echo "✅ Azure login confirmed"

# Show current subscription
SUBSCRIPTION=$(az account show --query name -o tsv)
echo "📋 Current subscription: $SUBSCRIPTION"

# Verify it's Azure for Students (optional)
if [[ "$SUBSCRIPTION" != *"Azure for Students"* ]]; then
    echo "⚠️  Warning: This doesn't appear to be an Azure for Students subscription"
    echo "Make sure you're using the correct subscription"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create service principal for GitHub Actions
echo "🤖 Creating service principal for GitHub Actions..."
SP_NAME="jobboard-github-actions"

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create service principal and capture JSON output
SP_JSON=$(az ad sp create-for-rbac \
    --name "$SP_NAME" \
    --role contributor \
    --scopes "/subscriptions/$SUBSCRIPTION_ID" \
    --json-auth)

# Parse the JSON output
SP_APP_ID=$(echo "$SP_JSON" | grep -o '"clientId": "[^"]*' | grep -o '[^"]*$')
SP_PASSWORD=$(echo "$SP_JSON" | grep -o '"clientSecret": "[^"]*' | grep -o '[^"]*$')
TENANT_ID=$(echo "$SP_JSON" | grep -o '"tenantId": "[^"]*' | grep -o '[^"]*$')

if [ -z "$SP_APP_ID" ] || [ -z "$SP_PASSWORD" ]; then
    echo "❌ Failed to create service principal"
    exit 1
fi

echo "✅ Service principal created"
echo ""
echo "📝 Save these values for GitHub Secrets:"
echo "AZURE_CREDENTIALS:"
cat << EOF
{
  "clientId": "$SP_APP_ID",
  "clientSecret": "$SP_PASSWORD",
  "subscriptionId": "$SUBSCRIPTION_ID",
  "tenantId": "$TENANT_ID"
}
EOF

# Generate database password
echo ""
echo "🔑 Generate a secure database password"
echo "Requirements: 8-41 characters, letters, numbers, and @#\$%^&+=*! symbols only"
read -p "Enter database password (or press Enter to generate): " DB_PASSWORD

if [ -z "$DB_PASSWORD" ]; then
    # Generate a secure password
    DB_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
    DB_PASSWORD="${DB_PASSWORD}1aA@"
fi

echo "✅ Database password set"

# Validate password format (basic check for length)
if [ ${#DB_PASSWORD} -lt 8 ] || [ ${#DB_PASSWORD} -gt 41 ]; then
    echo "❌ Invalid password length"
    echo "Must be 8-41 characters"
    exit 1
fi

echo ""
echo "📋 Setup Summary:"
echo "==============="
echo "✅ Azure CLI: Installed and logged in"
echo "✅ Service Principal: Created for GitHub Actions"
echo "✅ Database Password: Generated"
echo ""
echo "🔧 Next Steps:"
echo "1. Copy the AZURE_CREDENTIALS JSON above to GitHub Secrets"
echo "2. Add the following additional secrets to GitHub:"
echo "   - AZURE_STATIC_WEB_APPS_TOKEN (generate in Azure Portal)"
echo "   - ACR_REGISTRY_NAME (will be generated during deployment)"
echo "   - DB_HOST (will be generated during deployment)"
echo "   - DB_USER=jobboard_admin"
echo "   - DB_PASSWORD=$DB_PASSWORD"
echo "   - CONTAINER_APP_URL (will be generated during deployment)"
echo ""
echo "3. Run the deployment script:"
echo "   cd azure && ./deploy.sh dev"
echo ""
echo "4. Push to develop branch to trigger automatic deployment"
echo ""
echo "📚 See azure/README.md for detailed instructions"

# Save configuration for deployment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cat > "$SCRIPT_DIR/.env" << EOF
DB_PASSWORD="$DB_PASSWORD"
SUBSCRIPTION_ID="$SUBSCRIPTION_ID"
TENANT_ID="$TENANT_ID"
SP_CLIENT_ID="$SP_APP_ID"
EOF

echo ""
echo "💡 Configuration saved to azure/.env"