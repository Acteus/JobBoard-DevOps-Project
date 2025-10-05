# Azure Migration Guide

This directory contains all the necessary files and configurations to migrate your JobBoard application from AWS to Azure using a modern serverless architecture.

## 🏗️ Architecture Overview

### Current (AWS) vs New (Azure) Architecture

| Component | AWS | Azure (Serverless) |
|-----------|-----|-------------------|
| **Frontend** | S3 + CloudFront | **Azure Static Web Apps** |
| **Backend** | EC2 + Docker | **Azure Container Apps** |
| **Database** | RDS MySQL | **Azure Database for MySQL** |
| **Storage** | S3 | **Azure Blob Storage** |
| **CDN/Load Balancer** | CloudFront + ALB | **Azure Front Door** |
| **Container Registry** | ECR | **Azure Container Registry** |
| **Secrets** | AWS Secrets Manager | **Azure Key Vault** |
| **Monitoring** | CloudWatch | **Azure Monitor + App Insights** |

## 📋 Prerequisites

### Azure Subscription
- **Azure for Students** subscription (perfect for this migration!)
- Access to East Asia region
- Contributor role on the subscription

### Required Tools
- Azure CLI (`az`)
- GitHub repository with admin access
- Docker (for containerized deployment)

## 🚀 Quick Start

### 1. Initial Infrastructure Deployment

```bash
# Login to Azure
az login

# Navigate to azure directory
cd azure

# Deploy development environment
./deploy.sh dev

# Deploy production environment
./deploy.sh prod
```

### 2. Set up GitHub Secrets

Add the following secrets to your GitHub repository:

**Settings > Secrets and variables > Actions**

```
AZURE_CREDENTIALS          # Azure service principal JSON
AZURE_STATIC_WEB_APPS_TOKEN # Static Web Apps deployment token
ACR_REGISTRY_NAME          # Container registry name
DB_HOST                   # MySQL server FQDN
DB_USER                   # Database username
DB_PASSWORD               # Database password
CONTAINER_APP_URL         # Container app URL
```

### 3. Trigger Deployment

Push to your `develop` or `main` branch to trigger automatic deployment:

```bash
git push origin develop  # Deploy to development
git push origin main     # Deploy to production
```

## 📁 File Structure

```
azure/
├── azure-deploy.json          # Main ARM template
├── parameters.dev.json        # Development parameters
├── parameters.prod.json       # Production parameters
├── deploy.sh                  # Deployment script
└── README.md                  # This file

.github/workflows/
└── azure-deploy.yml           # Azure deployment workflow
```

## 🔧 Configuration Details

### Azure Database for MySQL
- **Engine**: MySQL 8.0.21
- **Tier**: Burstable (B1ms) - cost-effective for students
- **Storage**: 20 GB (can grow up to 100 GB)
- **Backup**: 7 days retention
- **High Availability**: Disabled (for cost optimization)

### Azure Container Apps
- **Runtime**: Node.js 18
- **Scale**: 0-10 replicas based on HTTP traffic
- **Resources**: 0.5 CPU, 1 GB RAM per instance
- **Environment Variables**: Configured for database connection

### Azure Static Web Apps
- **Build**: Integrated GitHub Actions build
- **Routing**: Automatic API integration
- **Authentication**: Built-in support (optional)

## 💰 Cost Optimization

### Azure for Students Benefits
- **$100 credit** for 12 months
- **Free tier** for most services used:
  - Azure Database for MySQL (250 GB server)
  - Azure Container Apps (up to 10 apps)
  - Azure Static Web Apps (Free tier)
  - Azure Blob Storage (5 GB)
  - Azure Container Registry (Basic tier)

### Monthly Cost Estimate (after free credits)
- **Database**: ~$15-20/month (Burstable tier)
- **Container Apps**: ~$10-15/month (pay-per-use)
- **Storage**: ~$1-2/month
- **Total**: ~$26-37/month

## 🔍 Monitoring & Troubleshooting

### Azure Monitor
- **Application Insights**: Automatic instrumentation
- **Log Analytics**: Centralized logging
- **Alerts**: Configurable notifications

### Common Issues

1. **Database Connection Issues**
   ```bash
   # Check firewall rules
   az mysql flexible-server firewall-rule list --resource-group jobboard-dev --name jobboard-dev-mysql

   # Add your IP if needed
   az mysql flexible-server firewall-rule create --resource-group jobboard-dev --name jobboard-dev-mysql --rule-name AllowMyIP --start-ip-address YOUR.IP --end-ip-address YOUR.IP
   ```

2. **Container App Logs**
   ```bash
   # View logs
   az containerapp logs show --name jobboard-dev-api --resource-group jobboard-dev

   # Stream logs
   az containerapp logs show --name jobboard-dev-api --resource-group jobboard-dev --follow
   ```

3. **Static Web App Issues**
   - Check build logs in GitHub Actions
   - Verify API routes in `frontend/src/App.js`
   - Ensure CORS is properly configured

## 🔄 Migration Timeline

### Phase 1: Infrastructure Setup (Day 1)
- [x] Create Azure resources using ARM template
- [x] Set up database and storage
- [x] Configure monitoring

### Phase 2: Application Deployment (Day 2-3)
- [ ] Deploy backend to Container Apps
- [ ] Deploy frontend to Static Web Apps
- [ ] Test database connectivity
- [ ] Verify application functionality

### Phase 3: Production Migration (Day 4-5)
- [ ] Deploy production environment
- [ ] Update DNS records (if needed)
- [ ] Load testing
- [ ] Go-live preparation

### Phase 4: Optimization (Day 6-7)
- [ ] Performance tuning
- [ ] Cost optimization
- [ ] Monitoring setup
- [ ] Documentation updates

## 📞 Support

### Useful Azure Links
- [Azure Portal](https://portal.azure.com)
- [Azure for Students](https://azure.microsoft.com/en-us/free/students/)
- [Azure Container Apps Documentation](https://docs.microsoft.com/en-us/azure/container-apps/)
- [Azure Static Web Apps Documentation](https://docs.microsoft.com/en-us/azure/static-web-apps/)

### Getting Help
1. Check this README first
2. Review Azure documentation
3. Check application logs in Azure Portal
4. Review GitHub Actions logs for deployment issues

## 🔐 Security Considerations

- Database firewall allows all IPs (0.0.0.0/0) - restrict in production
- Use Azure Key Vault for all secrets
- Enable Azure AD authentication for production
- Regular security scanning with GitHub Actions

## 🎯 Next Steps After Migration

1. **DNS Update**: Point your domain to Azure Front Door (if using custom domain)
2. **SSL Certificate**: Configure custom domains with SSL
3. **Performance Monitoring**: Set up detailed monitoring and alerting
4. **Backup Strategy**: Configure automated backups and disaster recovery
5. **Scaling**: Adjust auto-scaling rules based on traffic patterns

---

**Happy Deploying! 🚀**