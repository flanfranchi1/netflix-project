from pyspark.sql.functions import current_timestamp, input_file_name
from pyspark.sql.types import StructType

dbutils.widgets.text("storage_account", "netflixdatalakefl2026", "Storage Account Name")
dbutils.widgets.text("source_container", "raw"Source Container")
dbutils.widgets.text("target_container", "silver", "Target Container")
dbutils.widgets.text("file_name", "netflix_titles.csv", "File Name to Ingest")

storage_account = dbutils.widgets.get("storage_account")
source_container = dbutils.widgets.get("source_container")
target_container = dbutils.widgets.get("target_container")
file_name = dbutils.widgets.get("file_name")

base_path = f"abfss://{source_container}@{storage_account}.dfs.core.windows.net/"
target_path = f"abfss://{target_container}@{storage_account}.dfs.core.windows.net/"
checkpoint_path = f"abfss://{target_container}@{storage_account}.dfs.core.windows.net/_checkpoints/"

def ingest_table(table_name, file_name):
    print(f"Starting ingestion for: {table_name} from {file_name}...")
    
    source_file_path = f"{base_path}{file_name}"
    
    (spark.readStream
        .format("cloudFiles")
        .option("cloudFiles.format", "csv")
        .option("cloudFiles.inferColumnTypes", "true")
        .option("header", "true")
        .option("delimiter", ",")
        .load(source_file_path)
        .withColumn("ingestion_timestamp", current_timestamp())
        .withColumn("source_filename", input_file_name())
        .writeStream
        .format("delta")
        .option("checkpointLocation", f"{checkpoint_path}{table_name}")
        .option("mergeSchema", "true")
        .outputMode("append")
        .trigger(availableNow=True)
        .table(table_name)
    )
    print(f"Table {table_name} successfully updated!")

table_name = f"{target_container}_{file_name.replace('.csv', '')}"

ingest_table(table_name, file_name)