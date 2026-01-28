resource "azurerm_data_factory_pipeline" "github_ingestion" {
  name            = "pl_ingest_all_github_data"
  data_factory_id = azurerm_data_factory.data_factory.id
  depends_on = [
    azurerm_data_factory_dataset_delimited_text.ds_source_github,
    azurerm_data_factory_dataset_delimited_text.ds_sink_datalake,
    azurerm_data_factory_linked_service_azure_databricks.ls_databricks_fl2026
  ]
  activities_json = jsonencode(flatten([
    for file in local.github_csv_input_files : [
      {
        name = "Copy_${replace(file, ".", "_")}"
        type = "Copy"
        typeProperties = {
          source = {
            type           = "DelimitedTextSource"
            storeSettings  = { type = "HttpReadSettings", requestMethod = "GET" }
            formatSettings = { type = "DelimitedTextReadSettings" }
          }
          sink = {
            type           = "DelimitedTextSink"
            storeSettings  = { type = "AzureBlobFSWriteSettings" }
            formatSettings = { type = "DelimitedTextWriteSettings", quoteAllText = true, fileExtension = ".txt" }
          }
          enableStaging = false
        }
        inputs  = [{ referenceName = "ds_github_${replace(file, ".", "_")}", type = "DatasetReference" }]
        outputs = [{ referenceName = "ds_datalake_raw_${replace(file, ".", "_")}", type = "DatasetReference" }]
        policy  = { timeout = "0.12:00:00", retry = 0, secureOutput = false, secureInput = false }
      },

      {
        name = "Notebook_${replace(file, ".", "_")}"
        type = "DatabricksNotebook"
        linkedServiceName = {
          referenceName = "ls_databricks_fl2026"
          type          = "LinkedServiceReference"
        }
        typeProperties = {
          notebookPath = "/Shared/bronze_ingestion"

          baseParameters = {
            "storage_account"  = azurerm_storage_account.datalake.name
            "source_container" = "raw"
            "target_container" = "bronze"
            "file_name"        = file
          }
        }

        dependsOn = [
          {
            activity             = "Copy_${replace(file, ".", "_")}"
            dependencyConditions = ["Succeeded"]
          }
        ]

        policy = { timeout = "0.12:00:00", retry = 0 }
      }
    ]
  ]))
}

resource "azurerm_data_factory_trigger_schedule" "daily_trigger" {
  name            = "tr_daily_run_6am"
  data_factory_id = azurerm_data_factory.data_factory.id
  pipeline_name   = azurerm_data_factory_pipeline.github_ingestion.name

  interval   = 1
  frequency  = "Day"
  start_time = "2026-01-26T04:00:00Z"

  activated = true
}
