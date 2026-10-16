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
//******************************************************************************************

//Network security Group for WAN subnet
resource "azurerm_network_security_group" "nsg_wan" {
  name                = "nsg-${var.application_name}-${var.environment_name}-wan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_subnet_network_security_group_association" "assoc_wan" {
  subnet_id                 = azurerm_subnet.subnet_wan.id
  network_security_group_id = azurerm_network_security_group.nsg_wan.id
}

resource "azurerm_network_security_rule" "wan_rule_https_inbound" {
  name                        = "Allow_https_ipsec"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_wan.name
  protocol                    = "Tcp"
  priority                    = "200"
  direction                   = "Inbound"
  access                      = "Allow"
  source_address_prefix       = var.local_IP
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["443"]
}

resource "azurerm_network_security_rule" "wan_https8443_inbound" {
  name                        = "Allow_https"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_wan.name
  protocol                    = "Tcp"
  priority                    = "300"
  direction                   = "Inbound"
  access                      = "Allow"
  source_address_prefix       = var.local_IP
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["8443"]
}

resource "azurerm_network_security_rule" "wan_ssh_inbound" {
  name                        = "Allow_ssh"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_wan.name
  protocol                    = "Tcp"
  priority                    = "400"
  direction                   = "Inbound"
  access                      = "Allow"
  source_address_prefix       = var.local_IP
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["22"]
}

resource "azurerm_network_security_rule" "wan_ike_inbound" {
  name                        = "Allow_IKE"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_wan.name
  protocol                    = "Udp"
  priority                    = "500"
  direction                   = "Inbound"
  access                      = "Allow"
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["500"]
}

resource "azurerm_network_security_rule" "wan_ipsec_inbound" {
  name                        = "Allow_Ipsec"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_wan.name
  protocol                    = "Udp"
  priority                    = "600"
  direction                   = "Inbound"
  access                      = "Allow"
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["4500"]
}

resource "azurerm_network_security_rule" "wan_deny_inbound" {
  name                        = "Deny-all"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_wan.name
  protocol                    = "*"
  priority                    = "1000"
  direction                   = "Inbound"
  access                      = "Deny"
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
}
//**********************************************************************************************
//Create Network Security Group for workload subnet

resource "azurerm_network_security_group" "nsg_workload" {
  name                = "nsg-${var.application_name}-${var.environment_name}-workload"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_subnet_network_security_group_association" "assoc_workload" {
  subnet_id                 = azurerm_subnet.subnet_workload.id
  network_security_group_id = azurerm_network_security_group.nsg_workload.id
}


resource "azurerm_network_security_rule" "workload_ssh_inbound" {
  name                        = "Allow_ssh"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_workload.name
  protocol                    = "Tcp"
  priority                    = "200"
  direction                   = "Inbound"
  access                      = "Allow"
  source_address_prefix       = "10.20.0.0/24"
  source_port_range           = "*"
  destination_address_prefix  = "172.16.3.4"
  destination_port_ranges     = ["22"]
}

resource "azurerm_network_security_rule" "workload_deny_inbound" {
  name                        = "Deny-all-Inbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_workload.name
  protocol                    = "*"
  priority                    = "1000"
  direction                   = "Inbound"
  access                      = "Deny"
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
}


resource "azurerm_network_security_rule" "workload_https_outbound" {
  name                        = "Allow-HTTPS-Outbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_workload.name
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "172.16.3.4"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "443"
}


resource "azurerm_network_security_rule" "workload_deny_outbound" {
  name                        = "Deny-all-Outbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_workload.name
  protocol                    = "*"
  priority                    = "1000"
  direction                   = "Outbound"
  access                      = "Deny"
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
}
//*************************************************************************************************

//Create NSG for LAN subnet
resource "azurerm_network_security_group" "nsg_lan" {
  name                = "nsg-${var.application_name}-${var.environment_name}-lan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_subnet_network_security_group_association" "assoc_lan" {
  subnet_id                 = azurerm_subnet.subnet_lan.id
  network_security_group_id = azurerm_network_security_group.nsg_lan.id
}

resource "azurerm_network_security_rule" "lan_https_inbound" {
  name                        = "Allow-HTTPS-Outbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_lan.name
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = "172.16.3.4"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "443"
}


resource "azurerm_network_security_rule" "lan_ssh_outbound" {
  name                        = "Allow-SSH-from-VPN"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_lan.name

  priority                   = 200
  direction                  = "Outbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_address_prefix      = "10.20.0.0/24"
  source_port_range          = "*"
  destination_address_prefix = "*"
  destination_port_range     = "22"
}



resource "azurerm_network_security_rule" "lan_deny_outbound" {
  name                        = "Deny-all-outbound"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_lan.name

  priority  = 1000
  direction = "Outbound"
  access    = "Deny"
  protocol  = "*"

  source_address_prefix      = "*"
  source_port_range          = "*"
  destination_address_prefix = "*"
  destination_port_range     = "*"
}

