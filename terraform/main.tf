terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      tags,
    ]
  }

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  }
}

# NAT Gateway for private subnets
# Using only 1 NAT Gateway to reduce costs and EIP usage
resource "aws_eip" "nat" {
  count = var.enable_ha_nat ? length(var.public_subnet_cidrs) : 1
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count = var.enable_ha_nat ? length(var.public_subnet_cidrs) : 1

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    # Use first NAT Gateway for all private subnets when HA is disabled
    nat_gateway_id = var.enable_ha_nat ? aws_nat_gateway.main[count.index].id : aws_nat_gateway.main[0].id
  }

  tags = {
    Name = "${var.project_name}-private-rt-${count.index + 1}"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      subnet_id,
      route_table_id,
    ]
  }
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      subnet_id,
      route_table_id,
    ]
  }
}

# Security Groups
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-web-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

resource "aws_security_group" "app" {
  name_prefix = "${var.project_name}-app-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App port"
    from_port       = 3001
    to_port         = 3001
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  ingress {
    description     = "SSH"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"] # Restrict this in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

resource "aws_security_group" "db" {
  name_prefix = "${var.project_name}-db-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

# RDS MySQL Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db-${var.environment}"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.rds_instance_class

  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = 100
  storage_encrypted     = true

  db_name  = "jobboard"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  maintenance_window              = "sun:03:00-sun:04:00"
  backup_window                  = "02:00-03:00"
  backup_retention_period        = var.backup_retention_period
  copy_tags_to_snapshot         = true
  deletion_protection           = var.deletion_protection
  multi_az                      = var.multi_az
  auto_minor_version_upgrade    = var.auto_minor_version_upgrade
  allow_major_version_upgrade   = false
  apply_immediately             = var.environment == "dev" ? true : false

  skip_final_snapshot = var.environment == "dev" ? true : false
  final_snapshot_identifier = var.environment != "dev" ? "${var.project_name}-db-final-snapshot" : null

  tags = {
    Name = "${var.project_name}-db"
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      subnet_ids,
      tags,
    ]
  }

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# S3 Bucket for static assets
resource "aws_s3_bucket" "static_assets" {
  count = var.s3_bucket_name != "" ? 1 : 0

  bucket = var.s3_bucket_name

  tags = {
    Name = "${var.project_name}-static-assets"
  }
}

resource "aws_s3_bucket_ownership_controls" "static_assets" {
  count = var.s3_bucket_name != "" ? 1 : 0

  bucket = aws_s3_bucket.static_assets[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "static_assets" {
  count = var.s3_bucket_name != "" ? 1 : 0

  bucket = aws_s3_bucket.static_assets[0].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "static_assets" {
  count = var.s3_bucket_name != "" ? 1 : 0

  depends_on = [
    aws_s3_bucket_ownership_controls.static_assets,
    aws_s3_bucket_public_access_block.static_assets,
  ]

  bucket = aws_s3_bucket.static_assets[0].id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "static_assets" {
  count = var.s3_bucket_name != "" ? 1 : 0

  bucket = aws_s3_bucket.static_assets[0].id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ec2/${var.project_name}-app"
  retention_in_days = var.cloudwatch_retention

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      retention_in_days,
      tags,
    ]
    # Allow recreation if needed
    create_before_destroy = false
  }

  tags = {
    Name = "${var.project_name}-app-logs"
  }
}

# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      tags,
      name,
    ]
    create_before_destroy = false
  }

  tags = {
    Name = "${var.project_name}-ec2-profile"
  }
}

# EC2 Instance for Backend Application
resource "aws_instance" "app" {
  ami                  = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type        = var.instance_type
  key_name             = var.key_pair_name

  subnet_id                   = aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = false

  user_data = templatefile("${path.module}/user-data.sh", {
    db_host     = aws_db_instance.main.address
    db_user     = var.db_username
    db_pass     = var.db_password
    db_name     = "jobboard"
    s3_bucket   = var.s3_bucket_name != "" ? var.s3_bucket_name : ""
    environment = var.environment
  })

  monitoring = var.enable_monitoring

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name = "${var.project_name}-app-server"
  }
}

# Auto Scaling Group (for production use)
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-app-"
  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    db_host     = aws_db_instance.main.address
    db_user     = var.db_username
    db_pass     = var.db_password
    db_name     = "jobboard"
    s3_bucket   = var.s3_bucket_name != "" ? var.s3_bucket_name : ""
    environment = var.environment
  }))

  monitoring {
    enabled = var.enable_monitoring
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_type           = "gp3"
      volume_size           = 20
      delete_on_termination = true
      encrypted             = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-app-server"
    }
  }
}

# Load Balancer (for production use)
resource "aws_lb" "app" {
  count = var.environment == "prod" ? 1 : 0

  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.environment == "prod"

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      tags,
      name,
      security_groups,
      subnets,
    ]
  }

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "app" {
  count = var.environment == "prod" ? 1 : 0

  name     = "${var.project_name}-app-tg"
  port     = 3001
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 1800
    enabled         = false
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      tags,
      name,
      vpc_id,
    ]
  }

  tags = {
    Name = "${var.project_name}-app-tg"
  }
}

resource "aws_lb_listener" "http" {
  count = var.environment == "prod" ? 1 : 0

  load_balancer_arn = aws_lb.app[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app[0].arn
  }
}

resource "aws_lb_listener" "https" {
  count = var.certificate_arn != "" && var.environment == "prod" ? 1 : 0

  load_balancer_arn = aws_lb.app[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app[0].arn
  }
}