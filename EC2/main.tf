terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  /* backend "s3" {
    bucket  = "my-bucket-jirivasm"
    key     = "global/s3/terraform.tfstate"
    region  = "us-east-2"
    encrypt = true

  } */
}
data "aws_ami" "al2" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon"]
}
#Create Bucket
resource "aws_s3_bucket" "my-bucket" {
  bucket = "my-bucket-joser"
}
#create versioning for bucket
resource "aws_s3_bucket_versioning" "versioning_bucket" {
  bucket = aws_s3_bucket.my-bucket.bucket
  versioning_configuration {
    status = "Enabled"
  }
}
#encrypting bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "aws_s3_bucket_server_side_encryption" {
  bucket = aws_s3_bucket.my-bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
#Bucket Key
resource "aws_kms_key" "bucket_key" {
  description             = "s3Bucket key to hide terraform state file"
  deletion_window_in_days = 10
}

#Encrypting Key Pair
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
#Creating Key Pair
resource "aws_key_pair" "my_key" {
  key_name = "my_key"
  #Public Key
  public_key = tls_private_key.rsa.public_key_openssh
}
#Saving Private Key
resource "local_file" "TF_Key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "TF_Key.pem"
}
variable "ingressrules" {
  type    = list(number)
  default = [8080, 22]
}


resource "aws_security_group" "web_traffic" {
  name        = "Allow web traffic"
  description = "inbound ports for ssh and standard http and everything outbound"
  dynamic "ingress" {
    iterator = port
    for_each = var.ingressrules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Terraform" = "true"
  }
}