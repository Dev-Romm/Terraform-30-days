# Architecture Diagram - Day 4: Auto Scaling and Load Balancing

## Mermaid Diagram

```mermaid
graph TB
    %% Define styles
    classDef internet fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:black
    classDef alb fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:black
    classDef target fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:black
    classDef asg fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:black
    classDef ec2 fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:black

    %% Nodes
    A[🌐 Internet]:::internet
    B[⚖️ ALB<br/>Port 80<br/>terraform-asg-example]:::alb
    C[🎯 Target Group<br/>Health Checks<br/>terraform-asg-example]:::target
    D[📈 Auto Scaling Group<br/>2-10 Instances<br/>terraform-asg-example]:::asg
    E[💻 EC2 Instances<br/>t3.micro<br/>Amazon Linux 2<br/>Port 8080]:::ec2

    %% Connections
    A -->|HTTP Traffic| B
    B -->|Routes to| C
    C -->|Health Checks| D
    D -->|Contains| E

    %% Subgraph for AWS
    subgraph "AWS us-east-1"
        B
        C
        D
        E
    end

    %% Click events (for interactive versions)
    click B "https://console.aws.amazon.com/ec2/home?region=us-east-1#LoadBalancers:"
    click D "https://console.aws.amazon.com/ec2/home?region=us-east-1#AutoScalingGroups:"
    click E "https://console.aws.amazon.com/ec2/home?region=us-east-1#Instances:"
```

## Alternative: ASCII Art Diagram

```
┌─────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────┐
│   🌐        │     │   ⚖️            │     │   🎯            │     │   📈            │     │   💻        │
│  Internet   │────▶│ ALB (Port 80)  │────▶│ Target Group    │────▶│ Auto Scaling   │────▶│ EC2         │
│             │     │ Load Balancer  │     │ Health Checks   │     │ Group (2-10)   │     │ Instances   │
│             │     │                 │     │                 │     │                 │     │ Port 8080   │
└─────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────┘
```

## Terraform Graph Output

```
digraph G {
  rankdir = "RL";
  node [shape = rect, fontname = "sans-serif"];
  "aws_launch_template.myLT";
  "aws_autoscaling_group.myASG";
  "aws_lb.myALB";
  "aws_lb_target_group.asg";
  "aws_lb_listener.http";
  "aws_security_group.alb";
  "data.aws_vpc.default";
  "data.aws_subnets.default";
  // Dependencies between resources
}
```

## Resources Used

- **Launch Configuration**: Template for EC2 instances in ASG
- **Auto Scaling Group**: Scales between 2-10 t3.micro instances
- **Application Load Balancer**: Distributes traffic on port 80
- **Target Group**: HTTP health checks every 15 seconds
- **Security Group**: Allows inbound traffic on port 8080
- **Data Sources**: Default VPC and subnets
- **Region**: us-east-1