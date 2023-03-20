locals {
  vpc_cidr = "10.10.0.0/16" # modify this for VPC 
  root_bucket_name = "databricks-korea-rootbucket" # modify this for unique root dbfs s3 bucket name
  prefix = "databricks-donidoni" # modify this for resource naming 
  tags = {
    Owner = "databricks-${var.user_name}"
    Environment = "${var.env_name}"

    }
  force_destroy = true #destroy root bucket when deleting stack?
}
