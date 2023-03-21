# Output

output "databricks_host" {
  value = databricks_mws_workspaces.this.workspace_url
}
