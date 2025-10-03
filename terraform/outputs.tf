output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "db_address" {
  description = "RDS instance address"
  value       = aws_db_instance.main.address
  sensitive   = true
}

output "db_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
  sensitive   = true
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "ec2_instance_public_ip" {
  description = "EC2 instance public IP"
  value       = aws_instance.app.public_ip
}

output "ec2_instance_private_ip" {
  description = "EC2 instance private IP"
  value       = aws_instance.app.private_ip
}

output "s3_bucket_name" {
  description = "S3 bucket name for static assets"
  value       = var.s3_bucket_name != "" ? aws_s3_bucket.static_assets[0].bucket : null
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = var.s3_bucket_name != "" ? aws_s3_bucket.static_assets[0].arn : null
}

output "s3_bucket_website_url" {
  description = "S3 bucket website URL"
  value       = var.s3_bucket_name != "" ? "http://${aws_s3_bucket.static_assets[0].bucket}.s3-website-${var.aws_region}.amazonaws.com" : null
}

output "load_balancer_dns_name" {
  description = "Load balancer DNS name"
  value       = var.environment == "prod" ? aws_lb.app[0].dns_name : null
}

output "load_balancer_zone_id" {
  description = "Load balancer zone ID"
  value       = var.environment == "prod" ? aws_lb.app[0].zone_id : null
}

output "security_group_ids" {
  description = "Security group IDs"
  value = {
    web = aws_security_group.web.id
    app = aws_security_group.app.id
    db  = aws_security_group.db.id
  }
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.app.name
}

output "database_connection_string" {
  description = "Database connection string"
  value       = "mysql://${var.db_username}:${var.db_password}@${aws_db_instance.main.address}:${aws_db_instance.main.port}/jobboard"
  sensitive   = true
}

output "ssh_command" {
  description = "SSH command to connect to EC2 instance"
  value       = "ssh -i ${var.key_pair_name}.pem ec2-user@${aws_instance.app.public_ip}"
}

output "application_url" {
  description = "Application URL"
  value = var.environment == "prod" && var.domain_name != "" ? (
    var.certificate_arn != "" ? "https://${var.domain_name}" : "http://${var.domain_name}"
  ) : "http://${aws_instance.app.public_ip}:3001"
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    environment         = var.environment
    region             = var.aws_region
    project_name       = var.project_name
    backend_url        = "http://${aws_instance.app.private_ip}:3001"
    database_host      = aws_db_instance.main.address
    monitoring_enabled = var.enable_monitoring
    multi_az_enabled   = var.multi_az
  }
}