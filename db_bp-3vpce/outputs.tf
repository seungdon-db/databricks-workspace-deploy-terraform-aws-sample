// export host to be used by other modules
output "databricks_host" {
  value = databricks_mws_workspaces.this.workspace_url
}

output "arn" {
  value = aws_iam_role.cross_account_role.arn
}

