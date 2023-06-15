# Create UC Metastore 


resource "databricks_metastore" "this" {
  provider      = databricks.workspace
  name          = var.metastore_name
  #storage_root  = "s3://${aws_s3_bucket.metastore.id}/${var.metastore_label}"
  storage_root  = "s3://${aws_s3_bucket.metastore.id}"
  #storage_root ="s3://${local.prefix}-${var.metastore_storage_label}"
  force_destroy = true
  owner = var.databricks_account_username
}

resource "databricks_metastore_data_access" "this" {
  provider     = databricks.workspace  
  depends_on   = [ databricks_metastore.this ]
  metastore_id = databricks_metastore.this.id
  name         = aws_iam_role.metastore_data_access.name
  aws_iam_role { role_arn = aws_iam_role.metastore_data_access.arn }
  is_default   = true
}



resource "databricks_metastore_assignment" "default_metastore" {
 # depends_on           = [ databricks_metastore_data_access.metastore_data_access ]
 depends_on           = [ databricks_metastore_data_access.this ]
  workspace_id         = var.default_metastore_workspace_id
  metastore_id         = databricks_metastore.this.id
  default_catalog_name = "hive_metastore"
}



#Create User and Groups
/*
resource "databricks_user" "unity_users" {
  provider  = databricks.mws
  for_each  = toset(concat(var.databricks_users, var.databricks_metastore_admins))
  user_name = each.key
  force     = true
}

resource "databricks_group" "admin_group" {
  provider     = databricks.mws
  display_name = var.unity_admin_group
}

resource "databricks_group_member" "admin_group_member" {
  provider  = databricks.mws
  for_each  = toset(var.databricks_metastore_admins)
  group_id  = databricks_group.admin_group.id
  member_id = databricks_user.unity_users[each.value].id
}

resource "databricks_user_role" "metastore_admin" {
  provider = databricks.mws
  for_each = toset(var.databricks_metastore_admins)
  user_id  = databricks_user.unity_users[each.value].id
  role     = "account_admin"
}
*/

