terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
    features {}

}

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

resource "azurerm_data_factory_linked_service_web" "source_github" {
  name = "github-source-fl2026"
  data_factory_id = azurerm_data_factory.data_factory.id
  url = "https://raw.githubusercontent.com/anshlambagit/Netflix_Azure_Data_Engineering_Project/main/"
  authentication_type = "Anonymous"
}

resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "source_datalake" {
  name = "datalake-source-fl2026"
  data_factory_id = azurerm_data_factory.data_factory.id
  url = azurerm_storage_account.datalake.primary_dfs_endpoint
  use_managed_identity = true 
}
locals {
  github_csv_input_files = ["netflix_cast.csv", "netflix_category.csv", "netflix_countries.csv", "netflix_directors.csv", "netflix_titles.csv"]
}

resource "azurerm_data_factory_dataset_delimited_text" "ds_source_github" {
  for_each = toset(local.github_csv_input_files)
  name                = "ds_github_${replace(each.value, ".", "_")}"
  data_factory_id = azurerm_data_factory.data_factory.id
  linked_service_name = azurerm_data_factory_linked_service_web.source_github.name
  http_server_location {
    relative_url = each.value
    path = "RawData_AND_Notebooks/"
    filename = each.value
  }
  column_delimiter = ","
  row_delimiter = "\n"
  encoding = "UTF-8"
  quote_character = "\""
  escape_character = "\\"
  first_row_as_header = true
}

resource "azurerm_data_factory_dataset_delimited_text" "ds_sink_datalake" {
  for_each = toset(local.github_csv_input_files)
  name                = "ds_datalake_raw_${replace(each.value, ".", "_")}"
  data_factory_id = azurerm_data_factory.data_factory.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.source_datalake.name
  azure_blob_fs_location {
    file_system = "bronze"
    filename = each.value
  }
  column_delimiter = ","
  row_delimiter = "\n"
  encoding = "UTF-8"
  quote_character = "\""
  escape_character = "\\"
  first_row_as_header = true
}

resource "azurerm_data_factory_pipeline" "github_ingestion" {
  name = "pl_ingest_all_github_data"
  data_factory_id = azurerm_data_factory.data_factory.id
  depends_on = [ 
    azurerm_data_factory_dataset_delimited_text.ds_source_github,
    azurerm_data_factory_dataset_delimited_text.ds_sink_datalake
  ]
  activities_json = jsonencode([
    for file in local.github_csv_input_files : {
      name = "Copy_${replace(file, ".", "_")}"
      type = "Copy"
      policy = {
        timeout = "0.12:00:00"
        retry = 0
retryIntervalInSeconds = 30
secureOutput = false
secureInput = false
      }
      typeProperties = {
        source = {
          type = "DelimitedTextSource"
          storeSettings = {
            type = "HttpReadSettings"
            requestMethod = "GET"
          }
          formatSettings = {
            type = "DelimitedReadSettings"
          } 
        }
        sink = {
          type = "DelimitedTextSink"
          storeSettings = {
            type ="AzureBlobFSWriteSettings" 
          }
          formatSettings = {
            type = "DelimitedTextWriteSettings"
            quoteAllText = true
            fileExtension = ".txt"
          }
        }
        enableStaging = false
      }
      inputs = [
        {
          referenceName = "ds_github_${replace(file, ".", "_")}"
          type = "DatasetReference"
      }
      ]
      outputs = [
        {
          referenceName = "ds_datalake_raw_${replace(file, ".", "_")}"
          type = "DatasetReference"
        }
      ]
    }
  ])
}