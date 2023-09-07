
---

# Data Ingestion, Transformation, and Orchestration Pipeline (Prod)

This project implements a robust pipeline for efficiently ingesting, transforming, and orchestrating data from an S3 bucket into a data warehouse using AWS services. The pipeline is designed to handle varying file sizes and unknown file drop times, ensuring seamless data processing.

## Table of Contents

- [Introduction](#introduction)
  - [Unknown Challenges](#unknown-challenges)
- [Pre-Requisites](#pre-requisites)
- [Solution Overview](#solution-overview)
  - [Architecture](#architecture)
    - [Extract and Load to Datawarehouse Staging](#extract-and-load-to-datawarehouse-staging)
    - [Transform from Datawarehouse Staging to Datawarehouse Analytics](#transform-from-datawarehouse-staging-to-datawarehouse-analytics)
  - [Usage Instructions](#usage-instructions)
- [Conclusion](#conclusion)

## Introduction

Every day, files are dropped into the `d2b-internal-assessment-bucket\order` folder. These files need to be processed and loaded into a data warehouse for analysis. The process involves loading the files into a staging schema, transforming the data using DBT (Data Build Tool), and finally loading the transformed data into the data warehouse's analytics schema.
### Unknown Challenges

1. **File Drop Time**: The pipeline handles data files being dropped into the designated bucket at unpredictable times.
2. **Varying File Sizes**: Data files range from Megabytes to Gigabytes in size.
   
## Pre-Requisites

Ensure you have the following tools installed before deploying the pipeline:

- **Python 3.8+**: Refer to [this guide](https://docs.python-guide.org/starting/install3/win/) for Windows installation instructions.
- **Docker**: Install Docker by following the steps in the [Docker Installation Guide](https://docs.docker.com/engine/install/).
- **Airflow**: Install Airflow on Docker from [this guide](https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html).
- **AWS CLI**: Interact with AWS services using commands. Install AWS CLI via the [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
- **Terraform**: Provision and manage infrastructure in any cloud. Install Terraform using the [Terraform Installation Guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).

## Solution Overview

This pipeline efficiently processes data from source to data warehouse analytics, overcoming the challenges posed by uncertain timing and file size.

## Architecture

### Extract and Load to Datawarehouse Staging

![Extract and Load to Datawarehouse Staging Architecture](https://github.com/abdulqadir100/data2bots_accessement/blob/main/architecture/Screenshot%202023-08-21%20at%2016.51.14.png)
- A Lambda function is triggered by an S3 event creation action in the `d2b-internal-assessment-bucket/order/` folder.
- The Lambda function determines the target table based on the file name convention.
- A transient EMR cluster is created from the Lambda function to load CSV files from S3 to the Postgres staging environment.
- The EMR cluster is automatically terminated after the loading job is complete.

### Transform from Datawarehouse Staging to Datawarehouse Analytics

![Transform from Datawarehouse Staging to Datawarehouse Analytics Architecture](https://github.com/abdulqadir100/data2bots_accessement/blob/main/architecture/TL.png)

- A DBT project is set up for consistent data transformation.
- An EC2 instance is deployed to host a Docker container for Airflow, an orchestration tool.
- The Airflow instance orchestrates the DBT job, ensuring data transformation tasks are executed efficiently.
- DBT Docs is used to create and generate a data dictionary in the data warehouse, providing documentation for the transformed data.

## Usage Instructions

1. **Infrastructure Setup (Terraform)**

- **Configure AWS CLI**: Set up AWS Access Key ID, AWS Secret Access Key, and the default region using `aws configure`.
- **Terraform Initialization**: Navigate to the [terraform folder](prod/terraform_bot) and run `terraform init` to download required provider plugins and modules.
- **Generate Execution Plan**: Use `terraform plan -out=tfplan` to create an execution plan for applying changes.
- **Apply Changes**: Execute the plan using `terraform apply tfplan` to create AWS services:
- ```
     Outputs:

      ec2_subnet_id = "subnet-026feffe179eb5a59"
      job_flow_role = "emr-ec2-instance-profile"
      lambda_execution_role = "LambdaEMRExecutionRole"
      s3_bucket = "d2b-internal-assessment-bucket-abduafol4283"
      service_role = "EMRRole"
      ```
---

  - #### Services and roles created
  
    - #### EC2 (Elastic Compute Cloud) Service
    
      - **Roles:**
        - `EMREC2Role`: Role assumed by EC2 instances to perform encryption operations using the associated KMS key.
    
    - #### S3 (Simple Storage Service) Service
      
      - **Roles:**
        - `EMRAssetS3BucketEncryptionKey`: KMS key used for encryption of the `EMRAssetsS3Bucket`.
    
    - #### KMS (Key Management Service) Service
    
      - **Roles:**
        - `LambdaEMRExecutionRole`: Role assumed by Lambda functions for encryption operations using the `EMRAssetS3BucketEncryptionKey`.
        - `EMRRole`: Role assumed by the EMR service for encryption operations and EMR resource access.
        - `EMREC2Role`: Role assumed by EC2 instances for encryption operations and EC2 resource access.
    
    - #### IAM (Identity and Access Management) Service
    
      - **Roles:**
        - `LambdaEMRExecutionRole`: Role assumed by Lambda functions with permissions for encryption operations, Lambda execution, EMR access, and S3 access.
        - `EMRRole`: Role assumed by the EMR service with permissions for encryption operations and EMR resource access.
        - `EMREC2Role`: Role assumed by EC2 instances with permissions for encryption operations and EC2 resource access.
      - **Instance Profile:**
        - `EMREC2InstanceProfile`: Instance profile associated with EC2 instances in the EMR cluster, having the `EMREC2Role` attached.
  

---
2. **Lambda**
   - Lambda function : [code](prod/lambda/lambda_function.py)
   - Spark code to run on EMR through Lambda : [code](prod/lambda/emr_script_EL_staging.py)

2. **DBT Project Setup**
   - [DBT folder](prod/dbt_data2bots)

3. **Airflow Setup**
   - [Dockerfile](prod/airflow/Dockerfile)
   - Run `docker-compose up -d` to start the Airflow container. [docker-compose.yaml](prod/airflow/docker-compose.yaml)
   - dag to run dbt daily :[data2bot_dbt_dag.py](prod/airflow/dags/data2bot_dbt_dag.py)

4. **DBT Transformation Orchestration with Airflow**
   - dbt transformations [dbt-models](prod/airflow/dags/dbt_data2bots/models/abduafol4283_analytics)


## Conclusion

This automated data processing workflow provides a scalable and efficient solution for extracting, transforming, and loading data from the S3 bucket to the data warehouse analytics schema. The combination of AWS Lambda, EMR, DBT, and Airflow ensures that data processing tasks are executed reliably and can handle varying file sizes and arrival times. Additionally, the documentation generated by DBT Docs helps in understanding and maintaining the data transformations performed on the incoming data.

---


# Data Ingestion, Transformation, and Orchestration Pipeline (dev)

## Solution
- Download csv files from s3 to local using boto3 [extract](dev/extract.py)
- Load from local to Data warehouse staging [Load](dev/load_staging.py)
- set up dbt using `pip` and [requirements.txt](dev/requirements.txt)
- set up a `cron job` to automate dbt run daily
- load the transformed data to the S3 buckt [loads3](dev/load_s3.py)
