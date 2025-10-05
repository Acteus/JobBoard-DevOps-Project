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

# Check if Static Web Apps already exists (GitHub integration configured)
STATIC_WEB_APP_NAME="jobboard-${ENVIRONMENT}-swa"
if az staticwebapp show --name "$STATIC_WEB_APP_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    echo "📦 Static Web Apps '$STATIC_WEB_APP_NAME' already exists"
    echo "🔧 Using existing Static Web Apps with GitHub integration"

    # Deploy without Static Web Apps (it already exists)
    echo "🔍 Validating ARM template (without Static Web Apps)..."
    az deployment group validate \
        --resource-group "$RESOURCE_GROUP" \
        --template-file azure-deploy.json \
        --parameters @parameters.$ENVIRONMENT.json \
        --parameters databasePassword="$DB_PASSWORD" \
        --parameters skipStaticWebApp="true"

    echo "🚀 Deploying ARM template (without Static Web Apps)..."
    az deployment group create \
        --resource-group "$RESOURCE_GROUP" \
        --template-file azure-deploy.json \
        --parameters @parameters.$ENVIRONMENT.json \
        --parameters databasePassword="$DB_PASSWORD" \
        --parameters skipStaticWebApp="true" \
        --name "jobboard-deployment-$(date +%s)"
else
    echo "🆕 Static Web Apps doesn't exist, deploying with GitHub integration"
    echo "🔐 Please provide your GitHub token for repository access:"
    read -p "GitHub Token: " GITHUB_TOKEN

    if [ -z "$GITHUB_TOKEN" ]; then
        echo "❌ GitHub token is required for Static Web Apps deployment"
        echo "💡 If you already configured GitHub integration in Azure Portal, you can skip Static Web Apps deployment"
        read -p "Skip Static Web Apps deployment? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "⏭️ Skipping Static Web Apps deployment"
            SKIP_SWA=true
        else
            exit 1
        fi
    fi

    if [ "$SKIP_SWA" != "true" ]; then
        # Deploy with Static Web Apps
        echo "🔍 Validating ARM template..."
        az deployment group validate \
            --resource-group "$RESOURCE_GROUP" \
            --template-file azure-deploy.json \
            --parameters @parameters.$ENVIRONMENT.json \
            --parameters databasePassword="$DB_PASSWORD" \
            --parameters githubToken="$GITHUB_TOKEN"

        echo "🚀 Deploying ARM template..."
        az deployment group create \
            --resource-group "$RESOURCE_GROUP" \
            --template-file azure-deploy.json \
            --parameters @parameters.$ENVIRONMENT.json \
            --parameters databasePassword="$DB_PASSWORD" \
            --parameters githubToken="$GITHUB_TOKEN" \
            --name "jobboard-deployment-$(date +%s)"
    else
        # Deploy without Static Web Apps
        echo "🔍 Validating ARM template (without Static Web Apps)..."
        az deployment group validate \
            --resource-group "$RESOURCE_GROUP" \
            --template-file azure-deploy.json \
            --parameters @parameters.$ENVIRONMENT.json \
            --parameters databasePassword="$DB_PASSWORD" \
            --parameters skipStaticWebApp="true"

        echo "🚀 Deploying ARM template (without Static Web Apps)..."
        az deployment group create \
            --resource-group "$RESOURCE_GROUP" \
            --template-file azure-deploy.json \
            --parameters @parameters.$ENVIRONMENT.json \
            --parameters databasePassword="$DB_PASSWORD" \
            --parameters skipStaticWebApp="true" \
            --name "jobboard-deployment-$(date +%s)"
    fi
fi

# Get deployment outputs
echo "📋 Getting deployment outputs..."
DEPLOYMENT_NAME="jobboard-deployment-$(date +%s)"
az deployment group show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$DEPLOYMENT_NAME" \
    --query properties.outputs \
    --output table

echo "✅ Deployment completed successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Update your GitHub repository secrets with the database password"
echo "2. Push to trigger GitHub Actions deployment"
echo "3. Monitor deployment in Azure Portal"
echo ""

# Show URLs if available
if [ "$SKIP_SWA" != "true" ] && az staticwebapp show --name "$STATIC_WEB_APP_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    echo "🌐 Access your application:"
    echo "Frontend: https://your-static-web-app-url"
    echo "Backend API: https://your-container-app-url"
else
    echo "🌐 Azure Resources Deployed:"
    echo "✅ Database, Container Registry, Container Apps"
    echo "⏭️ Static Web Apps: Already configured with GitHub integration"
    echo ""
    echo "💡 Your frontend is managed by the existing Azure Static Web Apps"
    echo "🔗 Backend API: Will be available at container app URL after deployment"
fi