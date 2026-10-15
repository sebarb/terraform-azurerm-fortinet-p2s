//User Defined Route
resource "azurerm_route_table" "udr" {
  name                = "udr-${var.application_name}-${var.environment_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  route {
    name                   = "all_to_fortigate"
    address_prefix         = "0.0.0.0/0"
    next_hop_in_ip_address = azurerm_network_interface.nic_lan.private_ip_address
    next_hop_type          = "VirtualAppliance"
  }
}

resource "azurerm_subnet_route_table_association" "route_assoc" {
  route_table_id = azurerm_route_table.udr.id
  subnet_id      = azurerm_subnet.subnet_workload.id
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}
//Network security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.application_name}-${var.environment_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_network_security_rule" "nsg_rule_http" {
  name                        = "Allow_http"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  protocol                    = "Tcp"
  priority                    = "500"
  direction                   = "Inbound"
  access                      = "Allow"
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["80"]
}

resource "azurerm_network_security_rule" "nsg_rule_https" {
  name                        = "Allow_https"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  protocol                    = "Tcp"
  priority                    = "510"
  direction                   = "Inbound"
  access                      = "Allow"
  source_address_prefix       = var.local_IP
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["8443"]
}


resource "azurerm_network_security_rule" "nsg_rule_ssh" {
  name                        = "Allow_ssh"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  protocol                    = "Tcp"
  priority                    = "530"
  direction                   = "Inbound"
  access                      = "Allow"
  source_address_prefix       = var.local_IP
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["22"]
}

resource "azurerm_network_security_rule" "nsg_rule_ike" {
  name                        = "Allow_IKE"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  protocol                    = "Udp"
  priority                    = "540"
  direction                   = "Inbound"
  access                      = "Allow"
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["500"]
}

resource "azurerm_network_security_rule" "nsg_rule_ipsec" {
  name                        = "Allow_Ipsec"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  protocol                    = "Udp"
  priority                    = "550"
  direction                   = "Inbound"
  access                      = "Allow"
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["4500"]
}

resource "azurerm_network_security_rule" "nsg_rule_https_ipsec" {
  name                        = "Allow_https_ipsec"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  protocol                    = "Tcp"
  priority                    = "560"
  direction                   = "Inbound"
  access                      = "Allow"
  source_address_prefix       = var.local_IP
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["443"]
}

resource "azurerm_subnet_network_security_group_association" "wan_nsg" {
  subnet_id                 = azurerm_subnet.subnet_wan.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

