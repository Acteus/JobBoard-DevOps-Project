[![Azure Deployment](https://github.com/Acteus/JobBoard-DevOps-Project/actions/workflows/azure-deploy.yml/badge.svg?branch=development)](https://github.com/Acteus/JobBoard-DevOps-Project/actions/workflows/azure-deploy.yml)

# JobBoard-DevOps-Project
A scalable job board web application for minimum-wage earners, demonstrating Cloud and DevOps practices with **Azure Serverless Architecture** (migrating from AWS).

## Project Overview
This project is a full-stack job board web app for entry-level jobs (e.g., cashier, cook) in a single city. It includes:
- **Frontend**: React.js with modern UI components
- **Backend**: Node.js + Express API
- **Database**: MySQL (Azure Database for MySQL Flexible Server)
- **Cloud**: **Azure Serverless** (Static Web Apps, Container Apps, Blob Storage)
- **IaC**: Azure Resource Manager (ARM) Templates
- **Containerization**: Docker with Azure Container Registry
- **CI/CD**: GitHub Actions with Azure integration
- **Version Control**: Git/GitHub

## 🚀 Azure Migration Status
**✅ Phase 1 Complete**: Infrastructure planning and configuration files created
**🔄 Phase 2 In Progress**: Azure resource deployment and testing
**⏳ Phase 3 Pending**: Production migration and AWS cleanup

**Benefits of Azure Migration:**
- **70% cost reduction** using Azure for Students benefits
- **Serverless architecture** - auto-scaling, pay-per-use
- **Modern cloud-native services** - easier maintenance and deployment
- **Free tier eligibility** for most services


## Acknowledgments
The idea for this job board web application was inspired by my friends [Angel Osana](https://github.com/AngelOsana), [Raiza Palles](https://github.com/raizapalles), and [Alexsandra Duhac](https://github.com/alexsandraduhac2002-lab). Their insights into creating a platform for minimum-wage job seekers helped shape the vision for this project.

## Tech Stack

### Current Azure Architecture (Recommended)
- **Frontend**: React.js with Azure Static Web Apps
- **Backend**: Node.js + Express with Azure Container Apps
- **Database**: MySQL with Azure Database for MySQL Flexible Server
- **Cloud**: Microsoft Azure (Serverless)
  - Static Web Apps for frontend hosting
  - Container Apps for backend API
  - Blob Storage for static assets
  - Key Vault for secrets management
  - Monitor + Application Insights for observability
- **IaC**: Azure Resource Manager (ARM) Templates
- **Containerization**: Docker with Azure Container Registry
- **CI/CD**: GitHub Actions with Azure integration
- **Version Control**: Git/GitHub

### Legacy AWS Architecture (Deprecated)
- **Frontend**: React.js with S3 + CloudFront
- **Backend**: Node.js + Express with EC2
- **Database**: MySQL with RDS
- **Cloud**: Amazon Web Services
- **IaC**: Terraform
- **Containerization**: Docker with ECR
- **CI/CD**: GitHub Actions with AWS integration

## Repository Structure
```
JobBoard-DevOps-Project/
├── /frontend/                          # React frontend application
│   ├── src/                           # React source code
│   ├── public/                        # Static assets
│   └── package.json                   # Frontend dependencies
├── /backend/                          # Node.js/Express backend API
│   ├── server.js                      # Main server file
│   ├── routes/                        # API routes
│   └── package.json                   # Backend dependencies
├── /azure/                           # Azure migration files ⭐ NEW
│   ├── azure-deploy.json             # ARM template for infrastructure
│   ├── parameters.dev.json           # Dev environment parameters
│   ├── parameters.prod.json          # Prod environment parameters
│   ├── deploy.sh                     # Azure deployment script
│   ├── setup-azure.sh               # Azure setup helper script
│   └── README.md                     # Azure migration guide
├── /terraform/                       # Legacy AWS infrastructure (deprecated)
│   ├── main.tf                       # AWS Terraform configuration
│   └── variables.tf                  # AWS variables
├── /docker/                         # Docker configuration
│   ├── Dockerfile.backend           # Backend container
│   ├── Dockerfile.frontend         # Frontend container
│   └── docker-compose.yml           # Local development setup
├── /.github/workflows/              # CI/CD pipelines
│   ├── azure-deploy.yml            # Azure deployment workflow ⭐ NEW
│   └── ci-cd.yml                   # Legacy AWS workflow (deprecated)
├── /scripts/                        # Utility scripts
│   ├── setup-db.sql                # Database schema
│   └── *.sh                        # Various utility scripts
├── README.md                        # Project documentation
└── LICENSE                         # MIT License
```

## 🚀 Quick Start (Azure Migration)

### Prerequisites
- Git installed locally
- **Azure for Students account** ⭐ **FREE**
- Docker Desktop
- Node.js 18+
- GitHub account

### Step 1: Azure Environment Setup
```bash
# Navigate to Azure configuration
cd azure

# Run the setup script (requires Azure CLI)
./setup-azure.sh

# Deploy development infrastructure
./deploy.sh dev
```

### Step 2: Configure GitHub Secrets
The setup script will show you exactly which secrets to add to your GitHub repository.

### Step 3: Deploy Application
```bash
# Push to trigger automatic deployment
git push origin develop  # Deploy to development
git push origin main     # Deploy to production
```

## Legacy Setup Instructions (AWS)

### Prerequisites
- Git installed locally
- AWS account (Free Tier recommended)
- Docker Desktop
- Terraform CLI
- Node.js (if using Node backend) or PHP
- MySQL client
- GitHub account

### Step 1: Clone the Repository
```bash
git clone https://github.com/Acteus/JobBoard-DevOps-Project.git
cd JobBoard-DevOps-Project
```

### Step 2: Set Up the Backend
1. Navigate to `/backend`.
2. If using Node.js:
   ```bash
   npm install express mysql2 dotenv
   node server.js
   ```
3. If using PHP, set up a local server (e.g., `php -S localhost:8000`).
4. Configure environment variables in `.env`:
   ```
   DB_HOST=your-rds-endpoint
   DB_USER=admin
   DB_PASS=your-password
   DB_NAME=jobboard
   AWS_S3_BUCKET=your-bucket-name
   ```

### Step 3: Set Up the Database
1. Create an AWS RDS MySQL instance (Free Tier).
2. Run the SQL script in `/scripts/setup-db.sh` to create tables:
   ```sql
   CREATE TABLE jobs (
       id INT AUTO_INCREMENT PRIMARY KEY,
       title VARCHAR(255),
       employer VARCHAR(255),
       location VARCHAR(100),
       salary DECIMAL(10,2),
       posted_date DATE
   );
   ```

### Step 4: Containerize the App
1. Build and run the Docker container:
   ```bash
   docker build -t jobboard-app .
   docker run -p 3000:3000 jobboard-app
   ```
2. Use `docker-compose.yml` for multi-container setups (e.g., app + DB).

### Step 5: Provision AWS Infrastructure with Terraform
1. Navigate to `/terraform`.
2. Configure AWS credentials in `~/.aws/credentials`.
3. Initialize and apply Terraform:
   ```bash
   terraform init
   terraform apply
   ```
4. Example `main.tf`:
   ```hcl
   provider "aws" {
       region = "us-east-1"
   }

   resource "aws_instance" "app_server" {
       ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
       instance_type = "t2.micro"
       tags = {
           Name = "JobBoardApp"
       }
   }

   resource "aws_s3_bucket" "static_assets" {
       bucket = "jobboard-static-assets"
   }
   ```

### Step 6: Set Up CI/CD with GitHub Actions
1. Create a workflow in `.github/workflows/ci-cd.yml`:
   ```yaml
   name: CI/CD Pipeline
   on:
       push:
           branches: [ main ]
   jobs:
       build-and-deploy:
           runs-on: ubuntu-latest
           steps:
               - uses: actions/checkout@v3
               - name: Set up Node.js
                 uses: actions/setup-node@v3
                 with:
                     node-version: '16'
               - name: Install dependencies
                 run: npm install
               - name: Run tests
                 run: npm test
               - name: Build Docker image
                 run: docker build -t jobboard-app .
               - name: Deploy to AWS
                 env:
                     AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
                     AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
                 run: |
                     aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin your-ecr-repo
                     docker tag jobboard-app:latest your-ecr-repo/jobboard-app:latest
                     docker push your-ecr-repo/jobboard-app:latest
   ```
2. Add AWS credentials as GitHub Secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`).

### Step 7: Deploy Static Assets to S3
1. Upload frontend files to the S3 bucket:
   ```bash
   aws s3 sync ./frontend s3://jobboard-static-assets
   ```

### Step 8: Monitor with CloudWatch
1. Enable CloudWatch logs for the EC2 instance.
2. Set up metrics for CPU usage and network traffic.

## Architecture Comparison

### Current Azure Architecture (Target) ⭐
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Azure Static  │    │  Azure Container│    │  Azure Database │
│  Web Apps       │◄──►│  Apps           │◄──►│  MySQL          │
│                 │    │                 │    │                 │
│ • React Frontend│    │ • Node.js API   │    │ • Managed DB    │
│ • Global CDN    │    │ • Auto-scaling  │    │ • High Avail    │
│ • Free Tier     │    │ • Pay-per-use   │    │ • Auto-backup   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                ┌───────────────┼───────────────┐
                │    Azure Monitor &            │
                │   Application Insights       │
                └───────────────────────────────┘
```

**Benefits:**
- **70% cost reduction** with Azure for Students
- **Zero-maintenance** serverless infrastructure
- **Auto-scaling** based on traffic
- **Global CDN** included
- **Built-in monitoring** and logging

### Legacy AWS Architecture (Current)
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   S3 +          │    │  EC2 Instances  │    │  RDS MySQL      │
│  CloudFront     │◄──►│                 │◄──►│                 │
│                 │    │ • Node.js API   │    │ • Managed DB    │
│ • Static Assets │    │ • Fixed size    │    │ • High Avail    │
│ • Global CDN    │    │ • Manual scaling│    │ • Auto-backup   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                ┌───────────────┼───────────────┐
                │    CloudWatch Logs           │
                │     & Metrics                │
                └───────────────────────────────┘
```

## Migration Guide
For detailed Azure migration instructions, see [`azure/README.md`](azure/README.md).

### Migration Benefits
- **Cost**: ~$26-37/month vs ~$80-100/month on AWS
- **Maintenance**: Zero server management vs EC2 management
- **Scaling**: Automatic vs manual configuration
- **Deployment**: GitHub integration vs manual processes

## Development

### Local Development Setup
```bash
# Frontend development
cd frontend
npm install
npm start

# Backend development (in another terminal)
cd backend
npm install
npm run dev

# Access the application
# Frontend: http://localhost:3000
# Backend API: http://localhost:3001
```

### Docker Development
```bash
# Build and run with Docker Compose
cd docker
docker-compose up --build

# Access the application
# Frontend: http://localhost:3000
# Backend API: http://localhost:3001
```

### Azure Development
See [`azure/README.md`](azure/README.md) for Azure-specific development instructions.

## Testing
```bash
# Run frontend tests
cd frontend
npm test

# Run backend tests
cd backend
npm test

# Run all tests
npm run test:all
```


## Migration Timeline

### ✅ Phase 1: Planning & Configuration (Complete)
- [x] Azure architecture design
- [x] ARM templates creation
- [x] GitHub Actions workflows
- [x] Documentation updates

### 🔄 Phase 2: Infrastructure Deployment (In Progress)
- [ ] Azure resource provisioning
- [ ] Database migration
- [ ] Application deployment testing

### ⏳ Phase 3: Production Migration (Pending)
- [ ] Traffic migration strategy
- [ ] DNS updates
- [ ] AWS resource cleanup

**Estimated completion**: 4-5 days from Azure account setup

## Support & Resources

### Azure Migration Resources
- [Azure for Students](https://azure.microsoft.com/en-us/free/students/) - Free credits and services
- [Azure Static Web Apps Documentation](https://docs.microsoft.com/en-us/azure/static-web-apps/)
- [Azure Container Apps Documentation](https://docs.microsoft.com/en-us/azure/container-apps/)
- [Migration Guide](azure/README.md) - Detailed step-by-step instructions

### Development Resources
- [React Documentation](https://reactjs.org/docs)
- [Node.js Documentation](https://nodejs.org/docs)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License - see [LICENSE](LICENSE) file for details

---

**🚀 Ready to migrate to Azure? Start with [`azure/setup-azure.sh`](azure/setup-azure.sh)**

