import boto3
import json

# AWS Configuration
BUCKET_NAME = "auroraops-storage-nv"  # Change to your actual S3 bucket name
INPUT_FILE = "test_upload.txt"  # The file we uploaded earlier
OUTPUT_FILE = "processed_result.txt"  # Where the AI response will be stored
BEDROCK_MODEL = "anthropic.claude-v2"  # Example Bedrock model

# Initialize AWS Clients
s3_client = boto3.client("s3")
bedrock_client = boto3.client("bedrock-runtime")

def read_text_from_s3():
    """Download and read the uploaded text file from S3."""
    response = s3_client.get_object(Bucket=BUCKET_NAME, Key=INPUT_FILE)
    return response["Body"].read().decode("utf-8")

def process_with_bedrock(text):
    """Send the text to Amazon Bedrock for AI processing."""
    payload = {
        "prompt": f"Summarize the following text:\n{text}",
        "max_tokens": 200  # Limit response size
    }

    response = bedrock_client.invoke_model(
        modelId=BEDROCK_MODEL,
        body=json.dumps(payload),
        accept="application/json",
        contentType="application/json"
    )

    response_body = json.loads(response["body"].read().decode("utf-8"))
    return response_body["completion"]  # Extract AI response

def save_result_to_s3(result_text):
    """Save the AI-generated result back to S3."""
    s3_client.put_object(Bucket=BUCKET_NAME, Key=OUTPUT_FILE, Body=result_text)
    print(f"Processed result saved to S3 as {OUTPUT_FILE}")

if __name__ == "__main__":
    text_data = read_text_from_s3()
    ai_response = process_with_bedrock(text_data)
    save_result_to_s3(ai_response)
    print("Bedrock processing complete!")