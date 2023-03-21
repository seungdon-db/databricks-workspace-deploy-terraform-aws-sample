# Define locals to configure deployment

locals {
  vpc_cidr = "10.10.0.0/16"
  root_bucket_name = "datbricks-tf-rootbkt-korea-seoul-change-me"
  prefix = "workspace-name-change-me"
  tags = {
    Owner = "owner name change me"
    Environment = "Databricks development"
    }
  force_destroy = true #destroy root bucket when deleting stack?
  # endpoints per region 
  # https://docs.databricks.com/resources/supported-regions.html#privatelink 
  pl_service_relay = "com.amazonaws.vpce.ap-northeast-2.vpce-svc-0dc0e98a5800db5c4" # korea SSC relay endpoint
  pl_service_workspace = "com.amazonaws.vpce.ap-northeast-2.vpce-svc-0babb9bde64f34d7e" # korea workspace endpoint
}
