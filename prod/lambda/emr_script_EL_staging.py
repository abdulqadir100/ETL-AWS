import sys

from pyspark.sql import SparkSession
from pyspark import SparkContext
from pyspark.sql.types import *


spark = SparkSession \
        .builder \
        .appName("EL_app") \
        .getOrCreate()
        


def main():
    # get details from argv variable from aws lambda
    s3_bucket=sys.argv[1]
    s3_file=sys.argv[2]
    username  =sys.argv[3]
    password  =sys.argv[4]
    drive =sys.argv[5] 
    host_jdbc =sys.argv[6]
    table =sys.argv[7]

    s3_location="s3a://{}/{}".format(s3_bucket,s3_file)
    df = spark.read.format("csv").option("inferSchema","true").option("header","true").load(s3_location)
    # write to staging schema
    df.write \
    .format("jdbc") \
    .option("url", host_jdbc) \
    .option("dbtable", f"abduafol4283_staging.{table}") \
    .option("user", username) \
    .option("password", password) \
    .option("driver",drive) \
    .mode("overwrite") \
    .save()
main()
