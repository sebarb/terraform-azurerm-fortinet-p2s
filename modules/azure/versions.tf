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
    local = {
      source  = "hashicorp/local"
      version = "~>2.9.1"
    }
  }
  required_version = "~>1.16.0"
}
