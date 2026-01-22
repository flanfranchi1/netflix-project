terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {
    resource_group_name    = "rg-terraform-state"
    storage_account_name = "safetfstatefl2026"
    container_name       = "tfstate"
    key                  = "netflix-project.tfstate"
  }
}


provider "azurerm" {
  features {}
}
