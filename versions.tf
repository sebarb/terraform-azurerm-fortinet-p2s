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
    fortios = {
      source  = "fortinetdev/fortios"
      version = "~>1.26.0"
    }
  }
  required_version = "~>1.16.0"
}
provider "azurerm" {
  features {
  }
}

provider "fortios" {
  hostname = "${module.azure.public_ip_address}:8443"
  token    = var.fortios_api_token
  insecure = true

}

