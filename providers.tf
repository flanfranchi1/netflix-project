terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    databricks = {
      source = "databricks/databricks"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "safetfstatefl2026"
    container_name       = "tfstate"
    key                  = "netflix-project.tfstate"
  }
}

provider "azurerm" {
  features {}
}

provider "databricks" {
  host                        = azurerm_databricks_workspace.dbx_workspace.workspace_url
  azure_workspace_resource_id = azurerm_databricks_workspace.dbx_workspace.id
}
