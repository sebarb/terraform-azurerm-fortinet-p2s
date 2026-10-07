terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>5.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~>4.4.0"
    }
  }
}
provider "azurerm" {
  features {
  }
}
