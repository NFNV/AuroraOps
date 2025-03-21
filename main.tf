terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Ensures compatibility with stable AWS provider versions
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

# IAM Role for Bedrock & S3 Access
resource "aws_iam_role" "auroraops_bedrock_role" {
  name = "AuroraOpsBedrockRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "AuroraOps IAM Role"
    Environment = "Development"
  }
}

# Attach a policy to allow Bedrock to access S3
resource "aws_iam_policy" "auroraops_bedrock_policy" {
  name        = "AuroraOpsBedrockPolicy"
  description = "Allows Bedrock to access S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::auroraops-storage-nv/*" # Replace with your S3 bucket name
      }
    ]
  })
}

# Attach the policy to the IAM Role
resource "aws_iam_role_policy_attachment" "auroraops_bedrock_policy_attachment" {
  role       = aws_iam_role.auroraops_bedrock_role.name
  policy_arn = aws_iam_policy.auroraops_bedrock_policy.arn
}