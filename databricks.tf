resource "azurerm_databricks_workspace" "dbx_workspace" {
  name                = "dbx-netflix-fl2026"
  resource_group_name = azurerm_resource_group.rg_netflix.name
  location            = azurerm_resource_group.rg_netflix.location
  sku                 = "standard"

  tags = {
    Environment = "Portfolio"
  }
}


resource "azurerm_data_factory_linked_service_azure_databricks" "ls_databricks_fl2026" {
  name                = "ls_databricks_fl2026"
  data_factory_id     = azurerm_data_factory.data_factory.id
  description         = "connection made with previously created cluster"
  adb_domain          = "https://${azurerm_databricks_workspace.dbx_workspace.workspace_url}"
  msi_work_space_resource_id = azurerm_databricks_workspace.dbx_workspace.id
  existing_cluster_id = databricks_cluster.dbz_single_node.id
}

resource "azurerm_role_assignment" "adf_control_databricks" {
  scope                = azurerm_databricks_workspace.dbx_workspace.id
  role_definition_name = "Contributor" # Permite ao ADF iniciar/parar o cluster
  principal_id         = azurerm_data_factory.data_factory.identity[0].principal_id
}

resource "azurerm_databricks_access_connector" "unity" {
  name                = "dbx-access-connector-fl2026"
  resource_group_name = azurerm_resource_group.rg_netflix.name
  location            = azurerm_resource_group.rg_netflix.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "dbx_storage_access" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.unity.identity[0].principal_id
}

resource "databricks_cluster" "dbz_single_node" {
 cluster_name            = "netflix-lab-cluster"
  spark_version           = "13.3.x-scala2.12"
  node_type_id            = "Standard_D4s_v3"
  autotermination_minutes = 10
  spark_conf = {
    "spark.databricks.cluster.profile" = "singleNode"
    "spark.master"                     = "local[*]"
  }
  custom_tags = {
    "ResourceClass" = "SingleNode"
  }
  depends_on = [
    azurerm_databricks_workspace.dbx_workspace,
    azurerm_role_assignment.dbx_storage_access
  ]
}
