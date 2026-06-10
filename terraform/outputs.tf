###############################################################
# Outputs — values printed after terraform apply
# Useful for knowing where your app is running
###############################################################

output "ec2_public_ip" {
  description = "Public IP address of the NID application server"
  value       = aws_instance.nid_app.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.nid_app.public_dns
}

output "app_url" {
  description = "URL to access the NID Flask application"
  value       = "http://${aws_instance.nid_app.public_ip}:5000"
}

output "dashboard_url" {
  description = "URL to access the Plotly/Dash monitoring dashboard"
  value       = "http://${aws_instance.nid_app.public_ip}:5000/dashboard/"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket storing ML model artifacts"
  value       = aws_s3_bucket.model_artifacts.bucket
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.nid_vpc.id
}
