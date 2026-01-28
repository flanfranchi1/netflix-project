# outputs.tf

output "databricks_host" {
  description = "A URL do Workspace do Databricks"
  # O 'https://' é importante para clicar direto no terminal
  value       = "https://${azurerm_databricks_workspace.dbx_workspace.workspace_url}"
}