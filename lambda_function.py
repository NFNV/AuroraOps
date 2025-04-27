import boto3
import json
import requests
import os

s3_client = boto3.client('s3')

HF_API_KEY = os.getenv("HF_API_KEY")
HF_MODEL_URL = "https://api-inference.huggingface.co/models/facebook/bart-large-cnn"

def lambda_handler(event, context):
    try:
        # Extract bucket name and object key from the event
        bucket_name = event['Records'][0]['s3']['bucket']['name']
        object_key = event['Records'][0]['s3']['object']['key']

        print(f"Triggered by file: {object_key}")

        # Skip already processed summary files
        if "_summary" in object_key:
            print(f"Skipping already processed file: {object_key}")
            return {
                'statusCode': 200,
                'body': json.dumps('Skipped already processed summary file')
            }

        # Get the text file content
        response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
        text = response['Body'].read().decode('utf-8')

        # Send to Hugging Face for processing
        headers = {"Authorization": f"Bearer {HF_API_KEY}"}
        payload = {
            "inputs": f"Summarize the following text clearly:\n\n{text}",
            "parameters": {"max_length": 200}
        }
        hf_response = requests.post(HF_MODEL_URL, headers=headers, json=payload)

        if hf_response.status_code == 200:
            summary = hf_response.json()[0]['summary_text']
            print(f"Generated summary: {summary}")
        else:
            summary = f"Error: Hugging Face API returned {hf_response.status_code}"

        # Upload the processed result back to S3
        result_key = object_key.replace(".txt", "_summary.txt")
        s3_client.put_object(Bucket=bucket_name, Key=result_key, Body=summary.encode('utf-8'))

        return {
            'statusCode': 200,
            'body': json.dumps('File processed successfully')
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error processing file: {str(e)}")
        }