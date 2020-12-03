terraform {
  required_providers {
    azurerm = {
      version = ">= 2.2"
    }
  }
  required_version = ">= 0.14"
}

provider "azurerm" {
  features {}
}

