terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

locals {
  region = "us-east-1"
}

# Configure the AWS Provider
provider "aws" {
  region                   = local.region
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "myupgrad-aws-credentials"
}