

# Create S3 root bucket
resource "aws_s3_bucket" "this" {
  bucket = local.root_bucket_name
  acl    = "private"

  force_destroy = local.force_destroy

  versioning {
    enabled = false
  }

  tags = merge(local.tags, {
    Name = local.root_bucket_name
  })
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"
    actions = ["s3:GetObject",
      "s3:GetObjectVersion",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:PutObject",
    "s3:DeleteObject"]
    resources = [
      "${aws_s3_bucket.this.arn}/*",
      aws_s3_bucket.this.arn]
    principals {
      identifiers = ["arn:aws:iam::414351767826:root"]
      type        = "AWS"
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket     = aws_s3_bucket.this.id
  policy     = data.aws_iam_policy_document.this.json
}


# Create networking VPC resources

data "aws_availability_zones" "available" {
  state = "available"
}



# Databricks objects
# resource "databricks_mws_credentials" "this" {
#   provider         = databricks.accounts
#   credentials_name = "${local.prefix}-creds"
#   account_id       = var.databricks_account_id
#   #role_arn         = var.cross_account_arn
#   role_arn         = aws_iam_role.cross_account_role.arn
# }

# Generate credentials to create and thereafter enter the Databricks workspace
resource "databricks_mws_credentials" "this" {
  provider         = databricks.mws
  account_id       = var.databricks_account_id
  role_arn         = aws_iam_role.cross_account_role.arn
  credentials_name = "${local.prefix}-creds"
  depends_on       = [time_sleep.wait]
}


resource "databricks_mws_storage_configurations" "this" {
  provider                   = databricks.accounts
  account_id                 = var.databricks_account_id
  storage_configuration_name = "seungdon-tf-storage"
  bucket_name                = aws_s3_bucket.this.bucket
}


resource "databricks_mws_vpc_endpoint" "workspace" {
  provider = databricks.accounts
  account_id = var.databricks_account_id
  aws_vpc_endpoint_id = aws_vpc_endpoint.workspace.id
  vpc_endpoint_name = "Workspace endpoint for ${module.vpc.vpc_id}"
  region = var.region
  depends_on = [
    aws_vpc_endpoint.workspace
  ]
}

resource "databricks_mws_vpc_endpoint" "relay" {
  provider = databricks.accounts
  account_id = var.databricks_account_id
  aws_vpc_endpoint_id = aws_vpc_endpoint.relay.id
  vpc_endpoint_name = "VPC Relay endpoint for ${module.vpc.vpc_id}"
  region = var.region
  depends_on = [
    aws_vpc_endpoint.relay
  ]
}

resource "databricks_mws_private_access_settings" "this" {
  provider = databricks.accounts
  account_id = var.databricks_account_id
  private_access_settings_name = "Private Access for seungdon"
  region = var.region
  private_access_level = "ACCOUNT"
  public_access_enabled = true 
}

resource "databricks_mws_networks" "this" {
  provider = databricks.accounts
  account_id = var.databricks_account_id
  network_name = "${local.prefix}-network"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  security_group_ids = [aws_security_group.databricks_sg.id]

  vpc_endpoints {
    dataplane_relay = [databricks_mws_vpc_endpoint.relay.vpc_endpoint_id]
    rest_api = [databricks_mws_vpc_endpoint.workspace.vpc_endpoint_id]
  }

  depends_on = [
    aws_vpc_endpoint.relay,
    aws_vpc_endpoint.workspace
  ]
}


resource "databricks_mws_workspaces" "this" {
  provider = databricks.accounts
  account_id = var.databricks_account_id
  workspace_name = local.prefix
  deployment_name = local.prefix
  aws_region = var.region

  credentials_id = databricks_mws_credentials.this.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.this.storage_configuration_id
  network_id = databricks_mws_networks.this.network_id
  private_access_settings_id = databricks_mws_private_access_settings.this.private_access_settings_id
  pricing_tier = "ENTERPRISE"
  depends_on                 = [databricks_mws_networks.this]
}

