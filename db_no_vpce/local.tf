locals {
  vpc_cidr = "10.10.0.0/16"
  root_bucket_name = "databricks-rootbkt-workspace1"
  prefix = "workspace1"
  tags = {
    Owner = "databricks-${var.user_name}"
    Environment = "${var.env_name}"

    }
  force_destroy = true #destroy root bucket when deleting stack?
}
