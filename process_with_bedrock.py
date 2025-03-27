import boto3
import json
import requests
import os
import time
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# AWS Configuration
BUCKET_NAME = "auroraops-storage-nv"
INPUT_FILE = "test_upload.txt"
OUTPUT_FILE = "processed_result.txt"

# Hugging Face API Configuration
HF_API_KEY = os.getenv("HF_API_KEY")
HF_MODEL_URL = "https://api-inference.huggingface.co/models/google/flan-t5-base"

# Initialize AWS Clients
s3_client = boto3.client("s3")

def read_text_from_s3():
    """Download and read the uploaded text file from S3."""
    response = s3_client.get_object(Bucket=BUCKET_NAME, Key=INPUT_FILE)
    return response["Body"].read().decode("utf-8")

def process_with_hugging_face(text):
    """Send the text to Hugging Face API for processing, with retry mechanism."""
    headers = {"Authorization": f"Bearer {HF_API_KEY}"}
    payload = {
        "inputs": f"Please summarize the following in 1 paragraph:\n\n{text}",
        "parameters": {"max_length": 200}
    }

    for attempt in range(3):  # Retry up to 3 times
        response = requests.post(HF_MODEL_URL, headers=headers, json=payload)
        print(f"Attempt {attempt + 1}: Status Code {response.status_code}")
        print("Response:", response.text)

        if response.status_code == 200:
            return response.json()
        elif response.status_code in [500, 503]:
            print(f"Server error ({response.status_code}). Retrying in 5 seconds...")
            time.sleep(5)
        else:
            return {"error": f"Request failed with status code {response.status_code}, response: {response.text}"}

    return {"error": "Service unavailable after multiple retries"}

def save_result_to_s3(result_text):
    """Save the AI-generated result back to S3."""
    s3_client.put_object(Bucket=BUCKET_NAME, Key=OUTPUT_FILE, Body=json.dumps(result_text))
    print(f"Processed result saved to S3 as {OUTPUT_FILE}")

if __name__ == "__main__":
    text_data = read_text_from_s3()
    ai_response = process_with_hugging_face(text_data)
    save_result_to_s3(ai_response)
    print("Hugging Face processing complete!")