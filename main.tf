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

# IAM Role for Lambda execution
resource "aws_iam_role" "auroraops_lambda_role" {
  name = "AuroraOpsLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "AuroraOps Lambda IAM Role"
    Environment = "Development"
  }
}

# IAM Policy for Lambda to access S3
resource "aws_iam_policy" "auroraops_lambda_policy" {
  name        = "AuroraOpsLambdaPolicy"
  description = "Allows Lambda to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::auroraops-storage-nv/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to Lambda role
resource "aws_iam_role_policy_attachment" "auroraops_lambda_policy_attachment" {
  role       = aws_iam_role.auroraops_lambda_role.name
  policy_arn = aws_iam_policy.auroraops_lambda_policy.arn
}

# Lambda function
resource "aws_lambda_function" "auroraops_processor" {
  function_name = "auroraops-processor"
  role          = aws_iam_role.auroraops_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  filename      = "lambda_function_payload.zip" # You must manually zip and upload this file before applying

  environment {
    variables = {
      HF_API_KEY = "" # Set your Hugging Face API key here or use Secrets Manager later
    }
  }

  tags = {
    Name        = "AuroraOps Lambda Function"
    Environment = "Development"
  }
}

# Permission for S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auroraops_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.auroraops_bucket.arn
}

# S3 notification trigger for Lambda
resource "aws_s3_bucket_notification" "auroraops_bucket_notification" {
  bucket = aws_s3_bucket.auroraops_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.auroraops_processor.arn
    events              = ["s3:ObjectCreated:Put"]
    filter_suffix       = ".txt"
  }

  depends_on = [aws_lambda_permission.allow_s3_to_invoke_lambda]
}