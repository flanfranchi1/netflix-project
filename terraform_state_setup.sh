az group create --name rg-terraform-state --location eastus
az storage account create --name safetfstatefl2026 --resource-group rg-terraform-state --sku Standard_LRS --encryption-services blob
az storage container create --name tfstate --account-name safetfstatefl2026