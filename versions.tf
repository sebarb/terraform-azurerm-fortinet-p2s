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
      source = "fortinetdev/fortios"
    }
  }
}
provider "azurerm" {
  features {
  }
}

provider "fortios" {
  hostname = "${azurerm_public_ip.public_ip.ip_address}:8443"
  token    = var.fortios_api_token
  insecure = true

}

