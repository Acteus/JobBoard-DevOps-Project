#!/bin/bash

# User Data script for JobBoard EC2 instance
# This script runs on instance startup to configure the application

set -e

# Log all output to a file for debugging
exec > >(tee /var/log/user-data.log) 2>&1

echo "Starting JobBoard application setup..."

# Update system packages
yum update -y

# Install Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Install Docker
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Install MySQL client for database connections
yum install -y mysql

# Create application directory
mkdir -p /opt/jobboard
cd /opt/jobboard

# Create environment file
cat > .env << EOF
DB_HOST=${db_host}
DB_USER=${db_user}
DB_PASS=${db_pass}
DB_NAME=${db_name}
PORT=3001
NODE_ENV=${environment}
EOF

# Create docker-compose.yml
cat > docker-compose.yml << EOF
version: '3.8'

services:
  backend:
    image: jobboard-backend:latest
    restart: unless-stopped
    environment:
      DB_HOST: ${db_host}
      DB_USER: ${db_user}
      DB_PASS: ${db_pass}
      DB_NAME: ${db_name}
      PORT: 3001
      NODE_ENV: production
    ports:
      - "3001:3001"
    networks:
      - jobboard-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  jobboard-network:
    driver: bridge
EOF

# Create systemd service for the application
cat > /etc/systemd/system/jobboard.service << EOF
[Unit]
Description=JobBoard Application
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/jobboard
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable jobboard.service

# Install CloudWatch agent for monitoring
yum install -y amazon-cloudwatch-agent

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/opt/jobboard/logs/**",
            "log_group_name": "/aws/ec2/jobboard-app",
            "log_stream_name": "{hostname}"
          },
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/aws/ec2/jobboard-app",
            "log_stream_name": "{hostname}-user-data"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Create log directory
mkdir -p /opt/jobboard/logs

# Start the application
echo "Starting JobBoard application..."
systemctl start jobboard.service

# Wait for application to be ready
sleep 30

# Check if application is running
if curl -f http://localhost:3001/health > /dev/null 2>&1; then
    echo "JobBoard application started successfully!"
else
    echo "Warning: Application health check failed"
    journalctl -u jobboard.service --no-pager -n 20
fi

echo "Setup complete!"