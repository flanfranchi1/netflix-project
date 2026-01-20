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

  backend "azurerm" {
    source_group_name    = "rg-terraform-state"
    storage_account_name = "safetfstatefl2026"
    container_name       = "flstate"
    key                  = "netflix-project.tfstate"
  }
}
