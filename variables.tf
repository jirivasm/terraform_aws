variable "region" {
  default     = "us-east-2"
  description = "AWS Region"
}
variable "cluster_name" {
  default = "first-eks-cluster"
}
variable "s3_bucket_name" {
  default = "terraform-state-jirivasm"
}