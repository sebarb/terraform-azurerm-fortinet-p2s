//Create Vnet
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.application_name}-${var.environment_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["172.16.0.0/16"]
}
//Create subnets
//WAN subnet-fortigate port 1
resource "azurerm_subnet" "subnet_wan" {
  name                 = "subnet_WAN"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["172.16.1.0/24"]
}
//LAN subnet - fortigate port 2
resource "azurerm_subnet" "subnet_lan" {
  name                 = "subnet_LAN"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["172.16.2.0/24"]
}
//Workload subnet - workload subnet
resource "azurerm_subnet" "subnet_workload" {
  name                 = "subnet_workload"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["172.16.3.0/24"]
}
//Create public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "ip-${var.application_name}-${var.environment_name}"
  sku                 = "Standard"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}
