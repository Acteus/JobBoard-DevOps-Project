# JobBoard-DevOps-Project
A scalable job board web application for minimum-wage earners, demonstrating Cloud and DevOps practices with AWS, Docker, Terraform, and GitHub Actions.

## Project Overview
This project is a full-stack job board web app for entry-level jobs (e.g., cashier, cook) in a single city. It includes:
- **Frontend**: HTML, CSS, JavaScript (or React)
- **Backend**: Node.js + Express (or PHP)
- **Database**: MySQL (AWS RDS)
- **Cloud**: AWS (EC2, RDS, S3, CloudWatch)
- **IaC**: Terraform
- **Containerization**: Docker
- **CI/CD**: GitHub Actions
- **Version Control**: Git/GitHub


## Acknowledgments
The idea for this job board web application was inspired by my friends [Angel Osana](https://github.com/AngelOsana), [Raiza Palles](https://github.com/raizapalles), and [Alexsandra Duhac](https://github.com/alexsandraduhac2002-lab). Their insights into creating a platform for minimum-wage job seekers helped shape the vision for this project.

## Tech Stack
- **Frontend**: HTML, CSS, JavaScript (or React)
- **Backend**: Node.js + Express (or PHP)
- **Database**: MySQL (AWS RDS)
- **Cloud**: AWS (EC2, RDS, S3, CloudWatch)
- **IaC**: Terraform
- **Containerization**: Docker
- **CI/CD**: GitHub Actions
- **Version Control**: Git/GitHub

## Repository Structure
```
JobBoard-DevOps-Project/
├── /frontend/                # Frontend code (HTML/CSS/JS or React)
│   ├── index.html
│   ├── styles.css
│   └── app.js
├── /backend/                 # Backend code (Node.js/Express or PHP)
│   ├── server.js
│   └── routes/
├── /terraform/               # Terraform scripts for AWS infrastructure
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── /docker/                  # Docker configuration
│   ├── Dockerfile
│   └── docker-compose.yml
├── /.github/workflows/       # GitHub Actions CI/CD pipeline
│   └── ci-cd.yml
├── /scripts/                 # Utility scripts (e.g., DB setup, deployment)
│   └── setup-db.sh
├── README.md                 # Project documentation
├── architecture-diagram.png  # System architecture diagram
└── LICENSE                   # MIT License
```

## Setup Instructions

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
git clone https://github.com/your-username/JobBoard-DevOps-Project.git
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

## Architecture Diagram
- Frontend served from S3.
- Backend on EC2, connected to RDS MySQL.
- GitHub Actions automates testing and deployment.
- CloudWatch monitors app performance.

## How to Run Locally
1. Start the backend server (`node server.js` or `php -S localhost:8000`).
2. Open `frontend/index.html` in a browser or serve via S3.
3. Test API endpoints (e.g., `GET /api/jobs`).


## License
MIT License

