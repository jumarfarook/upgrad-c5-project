terraform {
  backend "s3" {
    bucket = "514-umarf-c5-bucket"
    key    = "514-course-project/terraform.tfstate"
    region = "us-east-1"
  }
}