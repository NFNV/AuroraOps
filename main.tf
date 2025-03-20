terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Ensures compatibility with stable AWS provider versions
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1" # Change this if needed
}

# Create an S3 bucket
resource "aws_s3_bucket" "auroraops_bucket" {
  bucket        = "auroraops-storage-nv" # Change to a unique name
  force_destroy = true                   # Allows Terraform to delete the bucket if needed

  tags = {
    Name        = "AuroraOps S3"
    Environment = "Development"
  }
}
