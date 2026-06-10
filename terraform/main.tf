###############################################################
# Network Intrusion Detection System — AWS Infrastructure
# Author: Sam Nakhjavan
# Region: eu-west-2 (London)
# Description: Flat Terraform config to provision a secure VPC,
#              EC2 instance, security groups, and S3 bucket
#              for ML model artifact storage.
###############################################################

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

###############################################################
# VPC
###############################################################

resource "aws_vpc" "nid_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Project     = var.project_name
    Environment = var.environment
  }
}

###############################################################
# Subnets
# Public subnet  — for the EC2 instance (accessible via SSH/HTTP)
# Private subnet — reserved for future DB or internal services
###############################################################

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.nid_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.nid_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.aws_region}b"

  tags = {
    Name        = "${var.project_name}-private-subnet"
    Project     = var.project_name
    Environment = var.environment
  }
}

###############################################################
# Internet Gateway + Route Table
# Allows the public subnet to reach the internet
###############################################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.nid_vpc.id

  tags = {
    Name        = "${var.project_name}-igw"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.nid_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

###############################################################
# Security Group
# Allows: SSH (port 22) and Flask app (port 5000) from your IP
# Blocks: everything else inbound
# Outbound: unrestricted (required for pip installs, S3 access)
###############################################################

resource "aws_security_group" "nid_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for NID Flask application"
  vpc_id      = aws_vpc.nid_vpc.id

  # SSH — restrict to your IP in production
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Flask app port
  ingress {
    description = "Flask application"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_app_cidr]
  }

  # Outbound — allow all (needed for pip, boto3 S3 calls)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

###############################################################
# IAM Role + Instance Profile
# Allows EC2 to read/write S3 (model artifacts only)
# Follows least-privilege principle
###############################################################

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ec2-role"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "s3_model_access" {
  name = "${var.project_name}-s3-model-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.model_artifacts.arn,
          "${aws_s3_bucket.model_artifacts.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

###############################################################
# S3 Bucket — Model Artifact Storage
# Stores trained .pkl files (scikit-learn models)
# Versioning enabled so you can roll back to previous models
###############################################################

resource "aws_s3_bucket" "model_artifacts" {
  bucket = "${var.project_name}-model-artifacts-${var.environment}"

  tags = {
    Name        = "${var.project_name}-model-artifacts"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "model_artifacts_versioning" {
  bucket = aws_s3_bucket.model_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block all public access — models should never be publicly accessible
resource "aws_s3_bucket_public_access_block" "model_artifacts_block" {
  bucket = aws_s3_bucket.model_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

###############################################################
# EC2 Instance — Flask Application Server
# Runs the NID Flask app + Dash dashboard
# Uses IAM instance profile for S3 access (no hardcoded keys)
###############################################################

resource "aws_instance" "nid_app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.nid_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = var.key_pair_name

  # User data script: installs dependencies and starts the Flask app on boot
  user_data = <<-EOF
    #!/bin/bash
    set -e
    yum update -y
    yum install -y python3 python3-pip git

    # Clone the NID application
    cd /home/ec2-user
    git clone https://github.com/SaeidNK/network-intrusion-detection.git nid
    cd nid

    # Install Python dependencies
    pip3 install -r requirements.txt

    # Start Flask app (background, persists after SSH exit)
    nohup python3 app.py > /var/log/nid-app.log 2>&1 &
  EOF

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true  # Encrypt root volume — good security practice
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.project_name}-app-server"
    Project     = var.project_name
    Environment = var.environment
  }
}
