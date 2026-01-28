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
    file_system = "raw"
    filename = each.value
  }
  column_delimiter = ","
  row_delimiter = "\n"
  encoding = "UTF-8"
  quote_character = "\""
  escape_character = "\\"
  first_row_as_header = true
}