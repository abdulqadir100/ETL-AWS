import os 
import boto3
from botocore import UNSIGNED
from botocore.client import Config

def upload_to_s3(local_file):
    current_directory = os.path.dirname(os.path.abspath(__file__))
    file_path = os.path.join(current_directory, local_file)
    try:
        s3_folder = 'insert-folder-name'
        bucket_name = "insert-bucket-name"
        s3 = boto3.client('s3', config=Config(signature_version=UNSIGNED))
        s3.upload_file(file_path, bucket_name, s3_folder + local_file)
        print("Upload successful!")
    except FileNotFoundError:
        print("The file was not found")
    
upload_to_s3(local_file='agg_public_holiday.csv')

upload_to_s3(local_file='agg_shipments.csv')

upload_to_s3(local_file='best_performing_product.csv')
