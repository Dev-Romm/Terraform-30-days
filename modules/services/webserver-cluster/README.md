# Webserver Cluster Module

This module deploys a highly available, auto-scaling webserver cluster with an Application Load Balancer (ALB). It automatically manages EC2 instance lifecycle, load balancing across availability zones, and health checking. The cluster runs a simple HTTP server on your specified port and can scale up or down based on demand.

## Environment-Aware Configuration

This module is fully environment-aware and supports three deployment environments: `dev`, `staging`, and `production`. The environment variable drives multiple conditional decisions:

- **dev**: t2.micro instances, 1-3 cluster size, no monitoring
- **staging**: t2.micro instances, 1-3 cluster size, no monitoring
- **production**: t2.medium instances, 3-10 cluster size, detailed monitoring enabled

## Inputs

| Name | Type | Description | Default | Required |
|------|------|-------------|---------|:--------:|
| `cluster_name` | `string` | The name prefix used for all cluster resources (ALB, ASG, security group, etc.) | N/A | Yes |
| `environment` | `string` | Deployment environment: dev, staging, or production | N/A | Yes |
| `ami_id` | `string` | The AMI ID for the EC2 instances to launch | N/A | Yes |
| `server_port` | `number` | Port on which the HTTP server listens | `80` | No |
| `web_message` | `string` | Message displayed on the web server homepage | `"Hello, World"` | No |
| `allowed_cidr_blocks` | `list(string)` | CIDR blocks allowed to access the load balancer | `["0.0.0.0/0"]` | No |
| `availability_zones` | `list(string)` | List of availability zones for distributing instances | `["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]` | No |
| `enable_alb` | `bool` | Whether to enable the Application Load Balancer | `true` | No |
| `enable_detailed_monitoring` | `bool` | Whether to enable detailed CloudWatch monitoring for EC2 instances | `false` | No |
| `create_dns_record` | `bool` | Whether to create a Route53 DNS record for the ALB | `false` | No |
| `domain_name` | `string` | Domain name for Route53 record (required if create_dns_record=true) | `""` | No |
| `use_existing_vpc` | `bool` | Whether to use an existing VPC (tagged Name=existing-vpc) or create a new one | `false` | No |

## Outputs

| Name | Description | Usage |
|------|-------------|-------|
| `alb_dns_name` | The DNS name of the Application Load Balancer (null if ALB disabled) | Use this to access your webserver cluster |
| `asg_name` | The name of the Auto Scaling Group | Reference for scaling policies or manual operations |
| `security_group_id` | The ID of the ALB security group | Use in `depends_on` instead of module reference (Gotcha 3) |
| `launch_template_id` | The ID of the EC2 launch template | Reference for ASG updates or troubleshooting |
| `launch_template_latest_version` | The latest version number of the launch template | Track template changes |
| `alb_arn` | The ARN of the Application Load Balancer (null if ALB disabled) | Use in other AWS resources that reference the ALB |
| `target_group_arn` | The ARN of the target group (null if ALB disabled) | Reference for custom target group rules or monitoring |
| `alarm_arn` | The ARN of the CloudWatch alarm for high CPU (null if monitoring disabled) | Reference for alarm actions or monitoring |
| `route53_record_name` | The name of the Route53 DNS record (null if DNS record disabled) | Reference for DNS management |
| `availability_zones_map` | A map of availability zones indexed by zone_0, zone_1, etc. | Reference for subnet or instance distribution logic |

## Usage Example

### Environment-Aware Configuration
```hcl
module "webserver_cluster" {
  source = "./modules/services/webserver-cluster"

  # Required inputs
  cluster_name = "prod-webservers"
  environment  = "production"  # Drives instance type, size, and monitoring
  ami_id       = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 in us-east-1
}
```

### Complete Configuration with All Features
```hcl
module "webserver_cluster" {
  source = "./modules/services/webserver-cluster"

  # Basic configuration
  cluster_name = "prod-webservers"
  environment  = "production"
  ami_id       = "ami-0c55b159cbfafe1f0"
  
  # Server configuration
  server_port   = 8080
  web_message   = "Welcome to Production"
  
  # Security configuration
  allowed_cidr_blocks = ["10.0.0.0/8", "203.0.113.0/24"]
  
  # Conditional features
  enable_alb               = true
  enable_detailed_monitoring = true
  create_dns_record        = true
  domain_name              = "api.example.com"
  use_existing_vpc         = false  # Create new VPC
  
  # Availability zones
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

output "website_url" {
  value = "http://${module.webserver_cluster.alb_dns_name}"
}

output "alarm_arn" {
  value = module.webserver_cluster.alarm_arn
}

output "dns_record" {
  value = module.webserver_cluster.route53_record_name
}
```

### Dev Environment (Minimal Resources)
```hcl
module "webserver_cluster" {
  source = "./modules/services/webserver-cluster"

  cluster_name = "dev-webservers"
  environment  = "dev"  # t2.micro, 1-3 instances, no monitoring
  ami_id       = "ami-0c55b159cbfafe1f0"
  
  # Minimal features for dev
  enable_detailed_monitoring = false
  create_dns_record          = false
  use_existing_vpc           = false
}
```

### Using Existing VPC
```hcl
module "webserver_cluster" {
  source = "./modules/services/webserver-cluster"

  cluster_name = "prod-webservers"
  environment  = "production"
  ami_id       = "ami-0c55b159cbfafe1f0"
  
  # Use existing VPC tagged "Name = existing-vpc"
  use_existing_vpc = true
}
```

### Using Outputs in Dependent Resources
```hcl
# CORRECT: Reference specific outputs (Gotcha 3)
resource "aws_autoscaling_policy" "scale_up" {
  autoscaling_group_name = module.webserver_cluster.asg_name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

# CORRECT: Depend on specific resource output
resource "aws_route53_record" "webserver" {
  count = module.webserver_cluster.alb_dns_name != null ? 1 : 0
  
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.example.com"
  type    = "A"
  alias {
    name                   = module.webserver_cluster.alb_dns_name
    zone_id                = module.webserver_cluster.alb_arn != null ? split("/", module.webserver_cluster.alb_arn)[1] : ""
    evaluate_target_health = true
  }
}
```

## Conditional Features

This module supports several optional features that can be enabled/disabled:

### Application Load Balancer (ALB)
- **Variable**: `enable_alb` (default: `true`)
- **When disabled**: No ALB, target group, or listener resources are created
- **When enabled**: Full ALB setup with health checks and routing

### Detailed Monitoring
- **Variable**: `enable_detailed_monitoring` (default: `false`)
- **When disabled**: Standard EC2 monitoring only
- **When enabled**: CloudWatch detailed monitoring (additional cost) + high CPU alarm

### DNS Record
- **Variable**: `create_dns_record` (default: `false`)
- **Requirements**: `domain_name` and Route53 zone must exist
- **When enabled**: Creates Route53 A record pointing to ALB

### VPC Selection
- **Variable**: `use_existing_vpc` (default: `false`)
- **When false**: Creates new VPC with CIDR `10.0.0.0/16`
- **When true**: Looks for VPC tagged `Name = "existing-vpc"`

## Module Gotchas & How We Avoided Them

### Gotcha 1: File Paths Inside Modules ❌ WRONG / ✅ CORRECT

**The Problem:**
When your module references a file using a relative path like `./user-data.sh`, Terraform resolves that path relative to where Terraform is run (the root module's working directory), NOT relative to the module itself. This breaks when the module is in a subdirectory.

**WRONG - This will fail:**
```hcl
# In modules/services/webserver-cluster/main.tf
resource "aws_launch_template" "example" {
  user_data = file("./user-data.sh")  # ❌ Looks for ./user-data.sh from WHERE terraform IS RUN
}
```

When you run Terraform from `root/`, it tries to find `root/user-data.sh`, not `root/modules/services/webserver-cluster/user-data.sh`.

**CORRECT - Use path.module:**
```hcl
# In modules/services/webserver-cluster/main.tf
resource "aws_launch_template" "example" {
  user_data = file("${path.module}/user-data.sh")  # ✅ Always relative to this module
}

# Or with templatefile for dynamic content:
user_data = templatefile("${path.module}/user-data.sh", {
  server_port = var.server_port,
  cluster_name = var.cluster_name
})
```

**Key Takeaway:**
Always use `${path.module}/` for any file references inside modules. `path.module` is a special variable that always points to the module's directory.

---

### Gotcha 2: Inline Blocks vs Separate Resources ❌ WRONG / ✅ CORRECT

**The Problem:**
Some AWS resources support BOTH inline configuration blocks AND separate resource types:
- `aws_security_group` with inline `ingress`/`egress` blocks vs `aws_security_group_rule`
- `aws_network_acl` with inline rules vs `aws_network_acl_rule`

If you mix both patterns (inline + separate), Terraform battles over who controls the rules and recreates resources constantly.

**WRONG - Don't do this:**
```hcl
# In a module - mixing both patterns
resource "aws_security_group" "alb" {
  name = "alb"
  
  # Inline ingress block
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }
}

resource "aws_security_group_rule" "custom_https" {  # ❌ Mixing patterns!
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}
```

This causes Terraform to fight over the security group configuration. Callers also cannot easily add rules.

**CORRECT - Use all separate resources:**
```hcl
# In the module: Create the security group without inline rules
resource "aws_security_group" "alb" {
  name        = "alb"
  description = "ALB security group"
  # NO inline ingress/egress blocks
}

# Define all rules as separate resources - this is FLEXIBLE
resource "aws_security_group_rule" "alb_http_inbound" {
  type              = "ingress"
  from_port         = var.server_port
  to_port           = var.server_port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP traffic"
}

resource "aws_security_group_rule" "alb_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound traffic"
}
```

**Why This Module Uses This Pattern:**
✅ Module callers can add their own `aws_security_group_rule` resources without modifying the module
✅ No conflicts between inline and separate resources
✅ Clear separation of concerns - each rule has a dedicated resource
✅ Easier to add/remove rules by adding/removing resources

**Key Takeaway:**
For modules: Always use separate resources (e.g., `aws_security_group_rule`) instead of inline blocks. This gives callers maximum flexibility to extend your module.

---

### Gotcha 3: Module Output Dependencies ❌ WRONG / ✅ CORRECT

**The Problem:**
When root configuration references a module output in `depends_on`, Terraform treats the ENTIRE MODULE as a dependency, not just the specific resource. If anything in the module changes, Terraform destroys and recreates all resources depending on that module, even if those resources shouldn't be affected.

**WRONG - Don't reference the entire module:**
```hcl
# In your root configuration
resource "aws_autoscaling_policy" "my_policy" {
  autoscaling_group_name = module.webserver_cluster.asg_name
  scaling_adjustment     = 1
  
  # ❌ WRONG: This depends on the ENTIRE module
  depends_on = [module.webserver_cluster]
}

# Result: If you update ANY resource in the module (like the web_message),
# Terraform might destroy and recreate this policy unnecessarily.
```

**CORRECT - Depend on specific outputs:**
```hcl
# In your root configuration
resource "aws_autoscaling_policy" "my_policy" {
  autoscaling_group_name = module.webserver_cluster.asg_name
  scaling_adjustment     = 1
  
  # ✅ CORRECT: Depend only on the specific output needed
  depends_on = [module.webserver_cluster.asg_name]
  
  # Even better: Often you don't need explicit depends_on at all
  # because Terraform infers dependencies from variable references
}
```

**This Module's Solution: Granular Outputs**
This module exposes separate outputs for each resource:
- `security_group_id` - for security group dependencies
- `launch_template_id` - for template dependencies
- `alb_arn` - for ALB dependencies
- `target_group_arn` - for target group dependencies
- `asg_name` - for ASG dependencies

```hcl
# Now callers can depend on only what they need:
resource "aws_route_table_association" "api" {
  depends_on = [module.webserver_cluster.security_group_id]  # ✅ Minimal dependency
  
  subnet_id      = aws_subnet.api.id
  route_table_id = aws_route_table.main.id
}
```

**Key Takeaway:**
✅ Always expose granular outputs from modules
✅ Callers should depend on specific outputs, not entire modules
✅ This reduces unnecessary resource recreation and speeds up Terraform operations

---

## Architecture

This module creates:

1. **Auto Scaling Group (ASG)** - Manages EC2 instance lifecycle, automatically launching and terminating instances based on demand
2. **Launch Template** - Defines EC2 configuration (AMI, instance type, security group, user data)
3. **Application Load Balancer (ALB)** - *Optional* - Distributes traffic across running instances when `enable_alb = true`
4. **Target Group** - *Optional* - Groups of instances to receive traffic; includes health checks when ALB enabled
5. **ALB Listener** - *Optional* - Routes HTTP traffic on your specified port when ALB enabled
6. **Security Group** - Controls inbound/outbound traffic
7. **Security Group Rules** - Separate rules for flexibility (addresses Gotcha 2)
8. **CloudWatch Alarm** - *Optional* - High CPU monitoring when `enable_detailed_monitoring = true`
9. **Route53 Record** - *Optional* - DNS record for ALB when `create_dns_record = true`
10. **VPC** - Either uses existing VPC (tagged `Name = "existing-vpc"`) or creates new VPC

The cluster automatically:
- Distributes instances across multiple availability zones
- Performs health checks every 15 seconds (when ALB enabled)
- Replaces unhealthy instances
- Scales up/down based on ASG min/max size (integrated with other tools for auto-scaling policies)
- Monitors CPU utilization (when detailed monitoring enabled)

## Limitations & Considerations

1. **HTTP Only** - This module only configures HTTP. For HTTPS, add an ACM certificate and update the listener configuration.
2. **No HTTPS/SSL** - Load balancer uses HTTP. Use `aws_lb_listener` with `protocol = "HTTPS"` and an ACM certificate for production.
3. **Single-port configuration** - To add multiple ports, extend the module or use additional security group rules.
4. **No auto-scaling policies** - This module creates the ASG but does NOT configure scaling policies. Use `aws_autoscaling_policy` to scale based on metrics.
5. **Example web server** - The included user data runs a simple `busybox` HTTP server for demonstration. Replace with your own application.
6. **VPC Flexibility** - Supports both new VPC creation and existing VPC usage (tagged `Name = "existing-vpc"`).
7. **Environment Validation** - Environment must be one of: `dev`, `staging`, `production`.
8. **DNS Requirements** - When `create_dns_record = true`, the specified `domain_name` must have an existing Route53 hosted zone.
9. **Monitoring Costs** - Detailed monitoring incurs additional CloudWatch costs when enabled.
10. **Conditional Dependencies** - Some outputs return `null` when features are disabled - always check for null values in dependent resources.

## Examples

### Development vs Production

```hcl
# Development: Small cluster
module "webserver_dev" {
  source = "./modules/services/webserver-cluster"
  
  cluster_name = "dev-webservers"
  ami_id       = data.aws_ami.linux2.id
  min_size     = 1
  max_size     = 3
  instance_type = "t3.micro"
  server_port  = 8080
  web_message  = "Development Server"
}

# Production: Larger cluster with monitoring
module "webserver_prod" {
  source = "./modules/services/webserver-cluster"
  
  cluster_name              = "prod-webservers"
  ami_id                    = data.aws_ami.linux2.id
  min_size                  = 3
  max_size                  = 20
  instance_type             = "t3.small"
  server_port               = 80
  web_message               = "Production Server"
  allowed_cidr_blocks       = ["203.0.113.0/24", "198.51.100.0/24"]
}
```

### Adding Custom Security Rules

```hcl
module "webserver_cluster" {
  source = "./modules/services/webserver-cluster"
  # ... configuration ...
}

# Module provides base rules; callers can add more
resource "aws_security_group_rule" "allow_internal_api" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.api.id
  security_group_id        = module.webserver_cluster.security_group_id
}
```

## Troubleshooting

**Instances not becoming healthy:** Check security group rules allow traffic on `server_port` and that the user data script runs without errors.

**Load balancer DNS not resolving:** Can take 1-2 minutes after module creation. Verify ALB exists in AWS console.

**Scaling not happening:** This module only provides the ASG. Add `aws_autoscaling_policy` resources to enable scaling based on CPU, request count, or custom metrics.

**Module changes cause resource recreation:** You may be using `depends_on = [module.webserver_cluster]`. Use specific granular outputs instead (Gotcha 3).

**Happy Terraforming!:**