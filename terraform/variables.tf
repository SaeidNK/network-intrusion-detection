###############################################################
# Variables — Network Intrusion Detection System
# All configurable values are defined here.
# Override in terraform.tfvars — never hardcode values in main.tf
###############################################################

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Project name used as a prefix for all resource names"
  type        = string
  default     = "nid"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet (EC2 lives here)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet (reserved for future use)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "allowed_ssh_cidr" {
  description = "Your IP address in CIDR notation — restricts SSH access. Use YOUR_IP/32 for single IP."
  type        = string
  default     = "0.0.0.0/0"  # Change this to your IP in production: e.g. "1.2.3.4/32"
}

variable "allowed_app_cidr" {
  description = "CIDR range allowed to access the Flask app on port 5000"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance. Default is Amazon Linux 2023 in eu-west-2."
  type        = string
  default     = "ami-0b4c7755cdf0d9219"  # Amazon Linux 2023, eu-west-2
}

variable "instance_type" {
  description = "EC2 instance type. t3.micro is free-tier eligible."
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of an existing EC2 Key Pair for SSH access. Create one in AWS Console first."
  type        = string
}
