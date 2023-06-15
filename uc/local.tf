locals {
    prefix ="dbx-uc-${var.region}"
    tags = {
    Owner = "databricks-${var.user_name}"
    Environment = "${var.env_name}"

    }
    force_destroy = true
}