import json
import urllib.parse
#import pandas  as pd
import boto3
from botocore.exceptions import ClientError
import re



def get_secret():
    secret_name = "data2botDB0secret"
    region_name = "us-east-1"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        raise e

    # Decrypts secret using the associated KMS key.
    secret = get_secret_value_response['SecretString']

    secret_dict = json.loads(secret)

    # return Database connection properties
    
    user = secret_dict["username"]
    pwd = secret_dict["password"]
    driver = "org.postgresql.Driver"
    url =  "jdbc:postgresql://data2botsdb0.c43zhgoyki2b.us-east-1.rds.amazonaws.com:5432/d2b_accessment"
    return user,pwd,driver,url

def db_tablename(file):

    if re.match(r'^order', file, re.IGNORECASE):
        return 'orders'
    elif re.match(r'^review', file, re.IGNORECASE):
        return 'reviews'
    elif re.match(r'^shipment', file, re.IGNORECASE):
        return 'shipment_deliveries'
    else :
        raise ValueError(f"Unrecognized file type: {file}")

emr = boto3.client('emr')

def lambda_handler(event, context):
    file_name = event['Records'][0]['s3']['object']['key'] # name of your raw files
    bucketName=event['Records'][0]['s3']['bucket']['name'] # name of your raw file bucket
    
    #determine table to load from the file name
    try : 
        table_name =  db_tablename(file=file_name)
    except Exception as ex:
       
        raise ex
    #get db credentials
    username,password,driver,jdbc_url  = get_secret()

    # location of code to run
    backend_code="s3://d2b-internal-assessment-bucket-abduafol4283/code-files/emr_script_EL_staging.py"
    
    # create a transient cluster to run spark job
    response = emr.run_job_flow(
        Name='aws_EL_job_cluster',
        LogUri='s3://d2b-internal-assessment-bucket-abduafol4283/logs/',
        ReleaseLabel='emr-6.0.0',
        Instances={
            'MasterInstanceType': 'm5.xlarge',
            'SlaveInstanceType': 'm5.large',
            'InstanceCount': 1,
            'KeepJobFlowAliveWhenNoSteps': False,
            'TerminationProtected': False,
            'Ec2SubnetId': 'subnet-026feffe179eb5a59'
        },
        Applications=[{'Name': 'Spark'}],
        Configurations=[
            {'Classification': 'spark-hive-site',
             'Properties': {
                 'hive.metastore.client.factory.class': 'com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory'}
             }
        ],
        VisibleToAllUsers=True,
        JobFlowRole='emr-ec2-instance-profile',
        ServiceRole='EMRRole',
        Steps=[
            {
                'Name': 'flow-log-analysis',
                'ActionOnFailure': 'TERMINATE_CLUSTER',
                'HadoopJarStep': {
                    'Jar': 'command-runner.jar',
                    'Args': [
                        'spark-submit',
                        '--deploy-mode', 'cluster',
                        '--executor-memory', '6G',
                        '--num-executors', '1',
                        '--executor-cores', '2',
                        backend_code,
                        bucketName,
                        file_name,
                        username,
                        password,
                        driver,
                        jdbc_url,
                        table_name
                    ]
                }
            }
        ]
    )
