terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
  #   See https://docs.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstatepineapple"
    container_name       = "tfstate-pg-tileserver"
    key                  = "terraform.tfstate"
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "pg_tileserver_rg" {
  name     = var.rg_name
  location = var.location
}