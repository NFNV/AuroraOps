# AuroraOps

AuroraOps is a fully serverless AI-powered cloud project that integrates AWS services with Hugging Face AI models. It automates the processing of text files uploaded to an S3 bucket by triggering a Lambda function that sends the content to an external AI API, processes the results, and stores the summarized output back in S3.

## 🚀 Architecture Overview

- **Infrastructure as Code (IaC):** Terraform
- **Compute:** Lambda
- **Storage:** S3
- **IAM:** Secure least-privilege roles for Lambda access
- **External AI Integration:** Hugging Face API
- **Trigger:** S3 Event Notification

## 🛠 How It Works

1. User uploads a `.txt` file to the S3 bucket 
2. The S3 event triggers the Lambda function automatically.
3. Lambda reads the text from the uploaded file.
4. Lambda sends the text to a Hugging Face AI model for processing.
5. Lambda writes the AI-generated response into a new file in the same bucket
6. Infinite recursion is avoided by detecting and skipping already processed summary files.

## 🧠 Main Technologies Used

- **AWS Lambda** (Serverless computing)
- **Amazon S3** (Object storage)
- **AWS IAM** (Identity and Access Management)
- **Terraform** (Infrastructure provisioning)
- **Python 3.10** (Lambda runtime)
- **Hugging Face Inference API** (AI text processing)

## 🔒 Security Considerations

- API keys are stored securely as environment variables inside Lambda.
- S3 bucket access is restricted via IAM policies.
- Lambda has a timeout configured to prevent long-running executions.

## 🌟 Future Improvements

- Integrate Bedrock or SageMaker instead of external Hugging Face APIs.
- Add a web frontend to upload files and monitor processing status.
- Improve prompt engineering to tailor AI responses better.
- Introduce cost monitoring with AWS Budgets or alarms.

## 👨‍💻 Author

Built by NV as a cloud engineering practice project.