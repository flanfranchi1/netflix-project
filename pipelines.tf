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