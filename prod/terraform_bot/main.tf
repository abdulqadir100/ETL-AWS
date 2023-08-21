variable "vpc_name" {
  description = "The VPC name will be prefixed to VPC resources"
  default     = "EMVPC"
}

variable "vpc_cidr" {
  description = "Please enter the IP range (CIDR notation) for this VPC"
  default     = "10.192.0.0/16"
}

variable "public_subnet1_cidr" {
  description = "IP range (CIDR notation) for the public subnet"
  default     = "10.192.10.0/24"
}

variable "private_subnet1_cidr" {
  description = "IP range (CIDR notation) for the private subnet"
  default     = "10.192.20.0/24"
}

variable "region" {
  description = "AWS region"
  default     = "us-east-1" # Replace with your desired region
}

variable "account_id" {
  description = "AWS Account ID"
  # Provide your actual AWS Account ID
  default = "642941490624"
}

provider "aws" {
  region = var.region # Adjust this to your desired region
}

data "aws_availability_zones" "available" {
  # No filters needed, it will retrieve all available availability zones in the region
}


resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = var.vpc_name
  }
}



resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name} Public Subnet"
  }
}

resource "aws_subnet" "private_subnet1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_subnet1_cidr
  availability_zone       = element(data.aws_availability_zones.available.names, 0)
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.vpc_name} Private Subnet"
  }
}

resource "aws_eip" "nat_gateway_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnet1.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.vpc_name} Public Route Table"
  }
}

resource "aws_route" "default_public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_route_table_association" "public_subnet1_association" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table1" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.vpc_name} Private Routes (AZ1)"
  }
}

resource "aws_route" "default_private_route1" {
  route_table_id         = aws_route_table.private_route_table1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

resource "aws_route_table_association" "private_subnet1_association" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.private_route_table1.id
}

resource "aws_security_group" "security_group" {
  name        = "Security group with no ingress rule"
  description = "Security group with no ingress rule"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "security_group_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.security_group.id
}

resource "aws_security_group_rule" "security_group_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.security_group.id
}

resource "aws_kms_key" "emr_asset_s3_bucket_encryption_key" {
  description         = "EMR Assets S3 bucket encryption KMS key"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.emr_kms_key_policy.json
}

data "aws_iam_policy_document" "emr_kms_key_policy" {
  statement {
    actions = [
      "kms:*",
    ]
    effect = "Allow"
    resources = [
      "*",
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
    ]
    effect = "Allow"
    resources = [
      "*",
    ]
    principals {
      type = "Service"
      identifiers = [
        "kms.amazonaws.com",
        "lambda.amazonaws.com",
        "s3.amazonaws.com",
        "ec2.amazonaws.com",
        "elasticmapreduce.amazonaws.com",
      ]
    }
  }
}

resource "aws_s3_bucket" "emr_assets_s3_bucket" {
  bucket = "d2b-internal-assessment-bucket-abduafol4283"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.emr_asset_s3_bucket_encryption_key.arn
      }
    }
  }
  force_destroy = true
}

resource "aws_s3_bucket_policy" "emr_asset_s3_bucket_bucket_policy" {
  bucket = aws_s3_bucket.emr_assets_s3_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "s3:*",
      Effect    = "Deny",
      Principal = "*",
      Resource = [
        aws_s3_bucket.emr_assets_s3_bucket.arn,
        "${aws_s3_bucket.emr_assets_s3_bucket.arn}/*",
      ],
      Condition = {
        Bool = {
          "aws:SecureTransport" : "false",
        },
      },
    }],
  })
}

resource "aws_iam_role" "LambdaEMRExecutionRole" {
  name = "LambdaEMRExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "allow_encryption_operations" {
  name        = "allow-encryption-operations"
  description = "Allow encryption operations"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"],
        Effect = "Allow",
        Resource = aws_kms_key.emr_asset_s3_bucket_encryption_key.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "allow_encryption_operations_attachment" {
  policy_arn = aws_iam_policy.allow_encryption_operations.arn
  role       = aws_iam_role.LambdaEMRExecutionRole.name
}

data "aws_iam_policy_document" "managed_policies" {
 version = "2012-10-17"
  statement {
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
    ]
    effect = "Allow"
    resources = [
      aws_kms_key.emr_asset_s3_bucket_encryption_key.arn,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "managed_policy_attachments" {
  role       = aws_iam_role.LambdaEMRExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

resource "aws_iam_role_policy_attachment" "emr_full_access_attachment" {
  role       = aws_iam_role.LambdaEMRExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticMapReduceFullAccess"
}

resource "aws_iam_role_policy_attachment" "athena_full_access_attachment" {
  role       = aws_iam_role.LambdaEMRExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonAthenaFullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_full_access_attachment" {
  role       = aws_iam_role.LambdaEMRExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "secret_access_attachment" {
  role       = aws_iam_role.LambdaEMRExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
resource "aws_iam_role" "emr_role" {
  name = "EMRRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "elasticmapreduce.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the EMR IAM policy to the role
resource "aws_iam_policy_attachment" "emr_role_policy_attachment" {
  name       = "EMRRolePolicyAttachment"
  policy_arn = aws_iam_policy.allow_encryption_operations.arn
  roles      = [aws_iam_role.emr_role.name]
}
resource "aws_iam_role_policy_attachment" "service_role_access_attachment" {
  role       = aws_iam_role.emr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticMapReduceFullAccess"
}


resource "aws_iam_role" "emr_ec2_role" {
    name = "EMREC2Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the EMR EC2 IAM policy to the role
resource "aws_iam_policy_attachment" "emr_ec2_role_policy_attachment" {
  name       = "EMREC2RolePolicyAttachment"
  policy_arn = aws_iam_policy.allow_encryption_operations.arn
  roles      = [aws_iam_role.emr_ec2_role.name]
}

resource "aws_iam_instance_profile" "emr_ec2_instance_profile" {
  name = "emr-ec2-instance-profile"
  role = aws_iam_role.emr_ec2_role.name
}

# ec2 for Airflow for orchestration
resource "aws_instance" "data2bot_instance" {
  ami           = "ami-08a52ddb321b32a8c"
  instance_type = "t2.micro"

  tags = {
    Name = "data2bots_instance"
  }
}


output "lambda_execution_role" {
  description = "Lambda role"
  value       = aws_iam_role.LambdaEMRExecutionRole.name
}

output "service_role" {
  description = "EMR role name"
  value       = aws_iam_role.emr_role.name
}

output "job_flow_role" {
  description = "EC2 role name"
  value       = aws_iam_instance_profile.emr_ec2_instance_profile.name
}

output "ec2_subnet_id" {
  description = "Private subnet ID for EMR"
  value       = aws_subnet.private_subnet1.id
}

output "s3_bucket" {
  description = "S3 bucket for EMR"
  value       = aws_s3_bucket.emr_assets_s3_bucket.id
}
