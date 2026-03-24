# Terraform 30 Days Challenge - Day 3: Deploying Your First Server

## Overview

This project is part of the **30-Day Terraform Challenge** organized by **HashiCorp User Group Meru** and **AWS AI/ML User Group Kenya**. Day 3 focuses on deploying your first EC2 server on AWS using Terraform.

## What This Project Does

This Terraform configuration creates:
- **EC2 Instance**: A t3.micro instance (Free Tier eligible) running Amazon Linux 2
- **Security Group**: Allows inbound HTTP traffic on port 8080 from anywhere
- **Web Server**: Simple web server serving "Hello, World" on port 8080

## Architecture

```
Internet → Security Group (Port 8080) → EC2 Instance → Web Server
```

## Prerequisites

Before you begin, ensure you have:

1. **AWS Account** with appropriate permissions
2. **Terraform** installed (v1.0+)
3. **AWS CLI** configured with your credentials
4. **Git** for version control

### Installation Requirements

```bash
# Install Terraform (if not already installed)
# Windows (using Chocolatey)
choco install terraform

# Or download from: https://www.terraform.io/downloads

# Configure AWS CLI
aws configure
```

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/Dev-Romm/Terraform-30-days.git
   cd "Day 3 Deploying Your First Server with Terraform/terraform"
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Review the plan**
   ```bash
   terraform plan
   ```

4. **Deploy the infrastructure**
   ```bash
   terraform apply
   ```

5. **Get the public IP and test**
   ```bash
   # Get the public IP
   aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id) --query "Reservations[0].Instances[0].PublicIpAddress" --output text

   # Test the web server (replace <public-ip> with actual IP)
   curl http://<public-ip>:8080
   ```

## Configuration Details

### Resources Created

| Resource | Type | Description |
|----------|------|-------------|
| `aws_instance.firstec2` | EC2 Instance | t3.micro instance with web server |
| `aws_security_group.secgroup` | Security Group | Allows port 8080 inbound traffic |

### Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | us-east-1 | AWS region for deployment |
| `vpc_name` | demo_vpc | Name of the VPC (not used yet) |
| `vpc_cidr` | 10.0.0.0/16 | VPC CIDR block (not used yet) |

## Usage Examples

### Access Your Web Server

After deployment, your EC2 instance will be running a simple web server. You can access it at:
```
http://<public-ip>:8080
```

This will display: **"Hello, World"**

### Clean Up

To destroy the infrastructure:
```bash
terraform destroy
```

## Troubleshooting

### Common Issues

1. **Free Tier Instance Type Error**
   - **Error**: `InvalidParameterCombination: The specified instance type is not eligible for Free Tier`
   - **Solution**: Use `t3.micro` instead of `t2.micro`

2. **Security Group Permission Denied**
   - **Error**: `InvalidGroup.NotFound: The security group does not exist`
   - **Solution**: Remove `terraform.tfstate*` files and reapply

3. **AMI Not Found**
   - **Error**: AMI ID not valid for the region
   - **Solution**: Update the AMI ID for your region

### Getting Help

- Check AWS service status: https://status.aws.amazon.com/
- Terraform documentation: https://www.terraform.io/docs
- AWS EC2 documentation: https://docs.aws.amazon.com/ec2/

## Challenge Information

- **Challenge**: 30-Day Terraform Challenge
- **Day**: 3 - Deploying Your First Server
- **Organizers**:
  - HashiCorp User Group Meru
  - AWS AI/ML User Group Kenya

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Thanks to HashiCorp User Group Meru and AWS AI/ML UG Kenya for organizing this challenge
- Special thanks to the Terraform and AWS communities for their excellent documentation and support

---

**Happy Terraforming! 🚀**