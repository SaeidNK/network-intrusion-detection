# Infrastructure — Network Intrusion Detection System

Terraform configuration to deploy the NID Flask application on AWS (eu-west-2 / London).

## What This Provisions

| Resource | Purpose |
|---|---|
| VPC (`10.0.0.0/16`) | Isolated network for all project resources |
| Public subnet (`10.0.1.0/24`) | EC2 instance lives here; has internet access via IGW |
| Private subnet (`10.0.2.0/24`) | Reserved for future database or internal services |
| Internet Gateway | Enables public subnet to reach the internet |
| Route Table | Routes public subnet traffic through the IGW |
| Security Group | Allows SSH (port 22) and Flask app (port 5000); blocks all else |
| EC2 (t3.micro) | Runs the NID Flask app and Dash dashboard |
| IAM Role + Profile | Grants EC2 least-privilege access to S3 only |
| S3 Bucket | Stores trained `.pkl` model artifacts; versioning enabled |

## Architecture

```
Internet
    │
    ▼
Internet Gateway
    │
    ▼
Public Subnet (10.0.1.0/24)
    │
    ├── Security Group (port 22, 5000)
    │
    └── EC2 Instance (t3.micro)
            │
            │ IAM Role (least-privilege)
            ▼
        S3 Bucket (model artifacts)
            └── nid.pkl, decision_tree.pkl, random_forest.pkl

Private Subnet (10.0.2.0/24)
    └── Reserved for future use (RDS, internal services)
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.3.0
- AWS CLI configured (`aws configure`)
- An existing EC2 Key Pair in eu-west-2 (create in AWS Console → EC2 → Key Pairs)

## Deployment

```bash
# 1. Clone and navigate
cd terraform/

# 2. Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your key pair name and IP address

# 3. Initialise Terraform (downloads AWS provider)
terraform init

# 4. Preview what will be created
terraform plan

# 5. Deploy
terraform apply

# 6. After apply, Terraform prints:
#    app_url       = "http://<IP>:5000"
#    dashboard_url = "http://<IP>:5000/dashboard/"
```

## Accessing the App

After `terraform apply` completes, wait ~60 seconds for the EC2 user data script to finish, then:

- **Flask app:** `http://<ec2_public_ip>:5000`
- **Dash dashboard:** `http://<ec2_public_ip>:5000/dashboard/`

SSH access:
```bash
ssh -i ~/.ssh/your-key.pem ec2-user@<ec2_public_ip>
```

## Teardown

To destroy all resources and avoid AWS charges:

```bash
terraform destroy
```

## Security Notes

- The EC2 instance root volume is encrypted at rest
- S3 bucket blocks all public access; models are private
- IAM role follows least-privilege: EC2 can only access this project's S3 bucket
- SSH is restricted to `allowed_ssh_cidr` in your `terraform.tfvars` — set this to your IP
- `terraform.tfvars` and state files are gitignored to avoid leaking sensitive values
