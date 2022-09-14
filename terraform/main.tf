# --------------------------------------------------------
# vpc and subnets
# --------------------------------------------------------

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.prefix}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "umarf-c5-project"
  }
}

module "self_ip_address" {
  source = "./modules/self_ip"
}

# --------------------------------------------------------
# IAM Role for ECR
# --------------------------------------------------------
resource "aws_iam_role" "role" {
  name               = "${var.prefix}-ecr-role"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": ["ec2.amazonaws.com"]
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF

  tags = {
    Terraform = "true"
  }
}

resource "aws_iam_policy" "policy" {
  name = "${var.prefix}-ecr-access-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "attach" {
  name       = "${var.prefix}-attach"
  roles      = ["${aws_iam_role.role.name}"]
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.prefix}-instance-profile"
  role = aws_iam_role.role.name
}

# --------------------------------------------------------
# Security group - SSH
# --------------------------------------------------------

resource "aws_security_group" "allow-ssh-self-ip" {
  name        = "allow-ssh"
  description = "allow SSH into the host"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from self ip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [module.self_ip_address.ipaddress]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name      = "allow-ssh"
    Terraform = "true"
  }
}

# --------------------------------------------------------
# Security group - Private instances SG
# --------------------------------------------------------

resource "aws_security_group" "allow-all-ingress-vpc" {
  name        = "allow-all-ingress-vpc"
  description = "allow all ingress from VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "all ingress from vpc"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name      = "allow-ingress-vpc"
    Terraform = "true"
  }
}

# --------------------------------------------------------
# Security group - Public web security group
# --------------------------------------------------------

resource "aws_security_group" "allow-ingress-http" {
  name        = "allow-ingress-http"
  description = "allow http ingress"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP from self ip"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [module.self_ip_address.ipaddress]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name      = "allow_http"
    Terraform = "true"
  }
}

# --------------------------------------------------------
# network interface for public subnet
# --------------------------------------------------------

resource "aws_network_interface" "terraform-nw-int-pub-sub" {
  subnet_id       = module.vpc.public_subnets[0]
  security_groups = ["${aws_security_group.allow-ssh-self-ip.id}"]

  tags = {
    Name      = "${var.prefix}-nw-int"
    Terraform = "true"
  }
}

# --------------------------------------------------------
# EC2 instance - bastion
# --------------------------------------------------------

resource "aws_instance" "bastion-ec2" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interface {
    network_interface_id = aws_network_interface.terraform-nw-int-pub-sub.id
    device_index         = 0
  }

  tags = {
    Name      = "${var.prefix}-bastion"
    Terraform = "true"
  }
}

# --------------------------------------------------------
# network interface for private subnet-1
# --------------------------------------------------------

resource "aws_network_interface" "terraform-nw-int-priv-sub-1" {
  subnet_id       = module.vpc.private_subnets[0]
  security_groups = ["${aws_security_group.allow-ingress-http.id}", "${aws_security_group.allow-all-ingress-vpc.id}"]

  tags = {
    Name      = "${var.prefix}-nw-int"
    Terraform = "true"
  }
}

# --------------------------------------------------------
# EC2 instance - jenkins
# --------------------------------------------------------

resource "aws_instance" "jenkins-ec2" {
  ami                  = var.ami
  instance_type        = var.instance_type
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.profile.name

  network_interface {
    network_interface_id = aws_network_interface.terraform-nw-int-priv-sub-1.id
    device_index         = 0
  }

  tags = {
    Name      = "${var.prefix}-jenkins"
    Terraform = "true"
  }
}

# --------------------------------------------------------
# network interface for private subnet-1
# --------------------------------------------------------

resource "aws_network_interface" "terraform-nw-int-priv-sub-2" {
  subnet_id       = module.vpc.private_subnets[0]
  security_groups = ["${aws_security_group.allow-ingress-http.id}", "${aws_security_group.allow-all-ingress-vpc.id}"]

  tags = {
    Name      = "${var.prefix}-nw-int"
    Terraform = "true"
  }
}

# --------------------------------------------------------
# EC2 instance - app
# --------------------------------------------------------

resource "aws_instance" "app-ec2" {
  ami                  = var.ami
  instance_type        = var.instance_type
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.profile.name

  network_interface {
    network_interface_id = aws_network_interface.terraform-nw-int-priv-sub-2.id
    device_index         = 0
  }

  tags = {
    Name      = "${var.prefix}-app"
    Terraform = "true"
  }
}

# --------------------------------------------------------
# ECR Repository
# --------------------------------------------------------
resource "aws_ecr_repository" "ecr-node-repo" {
  name                 = "${var.prefix}-node-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name      = "${var.prefix}-node-repo"
    Terraform = "true"
  }
}

# --------------------------------------------------------
# Application Load balancer and target group
# --------------------------------------------------------

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "${var.prefix}-alb"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = ["${aws_security_group.allow-ingress-http.id}"]

  target_groups = [
    {
      name_prefix      = "jenk-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"
      targets = {
        jenk_target = {
          target_id = aws_instance.jenkins-ec2.private_ip
          port      = 8080
        }
      }
    },
    {
      name_prefix      = "app-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"
      targets = {
        app_target = {
          target_id = aws_instance.app-ec2.private_ip
          port      = 8080
        }
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  http_tcp_listener_rules = [
    {
      http_tcp_listener_index = 0
      priority                = 1

      actions = [{
        type             = "forward"
        target_group_arn = module.alb.target_group_arns[0]
        protocol         = "HTTP"
      }]

      conditions = [{
        path_patterns = ["/jenkins", "/jenkins/*"]
      }]
    },
    {
      http_tcp_listener_index = 0
      priority                = 2

      actions = [{
        type             = "forward"
        target_group_arn = module.alb.target_group_arns[1]
        protocol         = "HTTP"
      }]

      conditions = [{
        path_patterns = ["/app", "/app/*"]
      }]
    }
  ]

  tags = {
    Name      = "${var.prefix}-alb"
    Terraform = "true"
  }
}