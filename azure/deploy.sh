#!/bin/bash

# Azure JobBoard Deployment Script
# Usage: ./deploy.sh [dev|prod]

set -e

ENVIRONMENT=${1:-dev}
RESOURCE_GROUP="jobboard-${ENVIRONMENT}"
LOCATION="East Asia"

echo "🚀 Starting Azure deployment for $ENVIRONMENT environment"
echo "=============================================="

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first:"
    echo "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure. Please login first:"
    echo "az login"
    exit 1
fi

echo "✅ Azure CLI is available and logged in"

# Create resource group if it doesn't exist
echo "📦 Creating resource group: $RESOURCE_GROUP"
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --tags environment="$ENVIRONMENT" project="jobboard" managed_by="terraform"

# Validate ARM template
echo "🔍 Validating ARM template..."
az deployment group validate \
    --resource-group "$RESOURCE_GROUP" \
    --template-file azure-deploy.json \
    --parameters @parameters.$ENVIRONMENT.json \
    --parameters databasePassword="$DB_PASSWORD"

# Deploy ARM template
echo "🚀 Deploying ARM template..."
az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file azure-deploy.json \
    --parameters @parameters.$ENVIRONMENT.json \
    --parameters databasePassword="$DB_PASSWORD" \
    --name "jobboard-deployment-$(date +%s)"

# Get deployment outputs
echo "📋 Getting deployment outputs..."
az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "jobboard-deployment-$(date +%s)" \
    --query properties.outputs \
    --output table

echo "✅ Deployment completed successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Update your GitHub repository secrets with the database password"
echo "2. Push to trigger GitHub Actions deployment"
echo "3. Monitor deployment in Azure Portal"
echo ""
echo "🌐 Access your application:"
echo "Frontend: https://your-static-web-app-url"
echo "Backend API: https://your-container-app-url"