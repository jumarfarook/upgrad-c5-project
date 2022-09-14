Contains terraform to build infrastructure in AWS

- Creates VPC in us-east1 region
- Creates two private and two public subnets
- Creates network interface to attach to the EC2
- Creates 3 EC2 instances - one in public subnet, and two in private subnet
- Creates security groups
- Creates Application Load Balancer and it's HTTP listener
- Creates two Target groups, one forwarding to jenkins and one forwarding to app instance
