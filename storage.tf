resource "azurerm_resource_group" "rg_netflix" {
  name = "netflix_project"
  location = "East US"
}

resource "azurerm_storage_account" "datalake" {
  name = "netflixdatalakefl2026"
  resource_group_name = azurerm_resource_group.rg_netflix.name
  location = azurerm_resource_group.rg_netflix.location
  account_tier   = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "data_containers" {
    for_each = toset(["raw", "bronze", "silver", "gold"])
    name = each.key
    storage_account_name = azurerm_storage_account.datalake.name
    container_access_type = "private"
}

resource "azurerm_data_factory" "data_factory" {
  name = "adf-netflix-project-fl2026"
  location = azurerm_resource_group.rg_netflix.location
  resource_group_name = azurerm_resource_group.rg_netflix.name
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "adf_storage_access" {
  scope = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id = azurerm_data_factory.data_factory.identity[0].principal_id
}
