terraform {
  required_version = ">= 1.2"
  
  backend "s3" {
    bucket = "terraform-state-jirivasm"
    key = "global/s3/terraform.tfstate"
    region = "us-east-2"  
    encrypt = true
  }
}
#set up provider with latest version
provider "aws" {
  region = var.region
}
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks_cluster_auth.token
}
#Data sources for cluster
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}
data "aws_eks_cluster_auth" "eks_cluster_auth" {
  name = module.eks.cluster_id
}
data "aws_availability_zones" "availability_zones" {
}
#S3 Buclket key
resource "aws_kms_key" "bucket_key" {
  description = "s3Bucket key to hide terraform state file"
  deletion_window_in_days = 10  
}
#S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.terraform_state.bucket
  versioning_configuration {
    status = "Enabled"
  }
}
#s3Bucket creation
resource "aws_s3_bucket" "terraform_state"{
  bucket = var.s3_bucket_name
}
#encrypting bucket info using Bucket Key
resource "aws_s3_bucket_server_side_encryption_configuration" "aws_s3_bucket_server_side_encryption" {
  bucket = aws_s3_bucket.terraform_state.bucket
  rule {
    apply_server_side_encryption_by_default{
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm = "aws:kms"
    }
  }
}
#Adding a security group
resource "aws_security_group" "all_worker_mngmt" {
  name_prefix = "all_worker_mngmt"
  vpc_id      = module.vpc.vpc_id

  #ssh port
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = ["10.0.0.0/8",
      "172.16.0.0/12",
    "192.168.0.0/16", ]
  }
}
data "aws_eks_cluster" "cluster_name" {
  name = module.eks.cluster_id
}
#creating a keypair
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
#use created keypair
resource "aws_key_pair" "my_key" {
  key_name   = "my_key"
  public_key = tls_private_key.rsa.public_key_openssh
  }
resource "local_file" "TF_Key" {
    content  = tls_private_key.rsa.private_key_pem
    filename = "TF_Key"
}
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14"

  name = "my-first-vpc"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.availability_zones.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  enable_vpn_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}
module "eks" {
  source                          = "terraform-aws-modules/eks/aws"
  cluster_name                    = var.cluster_name
  cluster_version                 = "1.22"
  subnet_ids                      = module.vpc.private_subnets
  cluster_endpoint_private_access = true
  vpc_id                          = module.vpc.vpc_id

  eks_managed_node_groups = {
    default_node_group = {
      min_size     = 1
      max_size     = 2
      desired_size = 2

      create_launch_template = false
      launch_template_name   = ""
      ami_id                 = "ami-052efd3df9dad4825"
      disk_size              = 50
      instance_types         = ["t2.micro"]

      additional_security_groups = [aws_security_group.all_worker_mngmt.id]
    }
  }
}


