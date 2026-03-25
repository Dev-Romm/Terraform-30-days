# Terraform 30 Days Challenge - Day 4: Auto Scaling and Load Balancing

## Overview

This project is part of the **30-Day Terraform Challenge** organized by **HashiCorp User Group Meru** and **AWS AI/ML User Group Kenya**. Day 4 focuses on implementing **Auto Scaling Groups (ASG)** and **Application Load Balancers (ALB)** for scalable web applications.

## What This Project Does

This Terraform configuration creates a **highly available and scalable web infrastructure**:
- **Launch Configuration**: Template for EC2 instances in the ASG
- **Auto Scaling Group**: Automatically scales EC2 instances (2-10 instances)
- **Application Load Balancer**: Distributes traffic across instances
- **Target Group**: Health checks and routing for the ASG
- **Security Groups**: Network security for ALB and instances
- **Data Sources**: Dynamically discovers default VPC and subnets

## Architecture

```
Internet → ALB (Port 80) → Target Group → Auto Scaling Group (2-10 EC2 instances)
                                    ↓
                            Health Checks & Routing
```

### Visual Architecture Diagram

For detailed visual representations, see [`architecture.md`](architecture.md) which contains:
- **Mermaid diagram** (renders on GitHub, VS Code, and online editors)
- **ASCII art diagram** for terminal/text viewing
- **Terraform graph output** showing resource dependencies

**Quick Architecture Overview:**
- 🌐 **Internet** → ⚖️ **ALB** (Port 80) → 🎯 **Target Group** → 📈 **Auto Scaling Group** (2-10 EC2 instances)

### Architecture Diagram Tools

1. **Mermaid** (Recommended - Text-based, version controlled)
   - Renders automatically on GitHub
   - VS Code extension available
   - Online editor: https://mermaid.live/

2. **Draw.io/diagrams.net** (Free online tool)
   - Drag-and-drop interface
   - AWS architecture icons available
   - Export to PNG/SVG

3. **Terraform Graph** (Command-line)
   ```bash
   terraform graph | dot -Tpng > architecture.png
   ```
   *Requires GraphViz installation*

   **Quick PNG Generation:**
   - Run `generate-png.bat` (Windows batch file)
   - Run `generate-png.ps1` (PowerShell script)
   - Then use online GraphViz tools to convert `graph.dot` to PNG

4. **AWS Architecture Icons** (Professional)
   - Official AWS icon library
   - Use in PowerPoint, Lucidchart, etc.

5. **CloudCraft or CloudMapper** (AWS-specific tools)
   - Generate diagrams from actual AWS resources

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
| `aws_launch_configuration.myLG` | Launch Configuration | Template for EC2 instances in ASG |
| `aws_autoscaling_group.myASG` | Auto Scaling Group | Scales between 2-10 EC2 instances |
| `aws_lb.myALB` | Application Load Balancer | Distributes traffic across instances |
| `aws_lb_target_group.asg` | Target Group | Health checks and routing for ASG |
| `aws_lb_listener.http` | Load Balancer Listener | Listens on port 80, returns 404 |
| `aws_security_group.alb` | Security Group | Network security for ALB and instances |
| `data.aws_vpc.default` | Data Source | Default VPC information |
| `data.aws_subnets.default` | Data Source | Default subnet information |

### Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | us-east-1 | AWS region for deployment |
| `instance_type` | t3.micro | EC2 instance type for ASG |
| `ami_id` | ami-053b0d53c279acc90 | AMI ID for EC2 instances |
| `port_number` | 8080 | HTTP port for web server |
| `web_message` | "Hello, World. I have used variables in Terraform." | Message displayed on web server |
| `allowed_cidr_blocks` | ["0.0.0.0/0"] | CIDR blocks allowed access |
| `security_group_name` | my-instance-sg-east1 | Name of security group |
| `instance_name` | my-first-ec2 | Name tag for instances |

## Usage Examples

### Access Your Load Balanced Application

After deployment, your ALB will distribute traffic across multiple EC2 instances. You can access it at:
```
http://<alb-dns-name>
```

This will display: **"Hello, World. I have used variables in Terraform."**

### Check Auto Scaling

- **View instances**: The ASG will create 2 instances initially
- **Test scaling**: The ASG can scale up to 10 instances based on load
- **Health checks**: ALB performs health checks on / path every 15 seconds

### Get Load Balancer DNS

```bash
# Get the ALB DNS name
terraform output alb_dns_name

# Or check AWS console
aws elbv2 describe-load-balancers --names terraform-asg-example --query 'LoadBalancers[0].DNSName' --output text
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
- **Day**: 4 - Auto Scaling and Load Balancing
- **Organizers**:
  - HashiCorp User Group Meru
  - AWS AI/ML User Group Kenya

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Acknowledgments

- Thanks to HashiCorp User Group Meru and AWS AI/ML UG Kenya for organizing this challenge
- Special thanks to the Terraform and AWS communities for their excellent documentation and support

---

**Happy Terraforming! 🚀**