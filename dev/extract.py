import boto3
from botocore import UNSIGNED
from botocore.client import Config
s3 = boto3.client('s3', config=Config(signature_version=UNSIGNED))
bucket_name = "d2b-internal-assessment-bucket"
response = s3.list_objects(Bucket=bucket_name, Prefix="orders_data")
print(response)
# download the orders.csv
s3.download_file(bucket_name, "orders_data/orders.csv", "orders.csv")
# download the reviews.csv
s3.download_file(bucket_name, "orders_data/reviews.csv", "reviews.csv")
# download the shipment_deliveries.csv
s3.download_file(bucket_name, "orders_data/shipment_deliveries.csv", "shipment_deliveries.csv")

