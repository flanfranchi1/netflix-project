resource "databricks_notebook" "nb_bronze_ingestion" {
  path     = "/Shared/bronze_ingestion"
  language = "PYTHON"


  source = "${path.module}/notebooks/bronze_ingestion.py"
}
