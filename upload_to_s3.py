import boto3
import os

# AWS Configuration
BUCKET_NAME = "auroraops-storage-nv"  # Change if necessary
LOCAL_FILE_PATH = "test_upload.txt"   # Change to the file you want to upload
S3_OBJECT_NAME = os.path.basename(LOCAL_FILE_PATH)  # Use same filename in S3

# Initialize S3 Client
s3_client = boto3.client("s3")

def upload_file_to_s3():
    try:
        s3_client.upload_file(LOCAL_FILE_PATH, BUCKET_NAME, S3_OBJECT_NAME)
        print(f"Successfully uploaded {LOCAL_FILE_PATH} to S3 bucket {BUCKET_NAME}")
    except Exception as e:
        print(f"Upload failed: {e}")

if __name__ == "__main__":
    upload_file_to_s3()