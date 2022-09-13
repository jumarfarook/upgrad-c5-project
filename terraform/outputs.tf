output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "app-ec2-private_ip" {
  description = "IP address of the app ec2"
  value       = aws_instance.app-ec2.private_ip
}

output "jenkins-ec2-private_ip" {
  description = "IP address of the jenkins ec2"
  value       = aws_instance.jenkins-ec2.private_ip
}

output "bastion-ec2-public_ip" {
  description = "IP address of the bastion ec2"
  value       = aws_instance.bastion-ec2.public_ip
}