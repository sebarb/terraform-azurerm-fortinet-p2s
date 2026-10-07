//Create Resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.application_name}-${var.environment_name}"
  location = var.location
}
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

//Create NIC interfaces for forgigate
resource "azurerm_network_interface" "nic_wan" {
  name                = "nic_wan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  ip_configuration {
    name                          = "ipconfig_wan"
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.16.1.4"
    subnet_id                     = azurerm_subnet.subnet_wan.id
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
  ip_forwarding_enabled = true
}
resource "azurerm_network_interface" "nic_lan" {
  name                = "nic_lan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  ip_configuration {
    name                          = "ipconfig_lan"
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.16.2.4"
    subnet_id                     = azurerm_subnet.subnet_lan.id
  }
  ip_forwarding_enabled = true
}
//Create NIC interface for Linux VM 
resource "azurerm_network_interface" "nic_workload" {
  name                = "nic_workload"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  ip_configuration {
    name                          = "ipconfig_workload"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subnet_workload.id
  }
}
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
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["443"]
}


resource "azurerm_network_security_rule" "nsg_rule_ssh" {
  name                        = "Allow_ssh"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  protocol                    = "Tcp"
  priority                    = "530"
  direction                   = "Inbound"
  access                      = "Allow"
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["22"]
}



resource "azurerm_subnet_network_security_group_association" "wan_nsg" {
  subnet_id                 = azurerm_subnet.subnet_wan.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

//Create Linux VM workload
resource "azurerm_linux_virtual_machine" "vm_workload" {
  name                            = "vm-${var.application_name}-${var.environment_name}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_b1s"
  admin_username                  = "localadmin"
  admin_password                  = var.admin_pass
  disable_password_authentication = false

  admin_ssh_key {
    username   = "localadmin"
    public_key = tls_private_key.ssh_key.public_key_openssh
  }
  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  network_interface_ids = [
    azurerm_network_interface.nic_workload.id
  ]
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}


//Create Fortigate VM
resource "azurerm_linux_virtual_machine" "vm_fortigate" {
  name                            = "nva-${var.application_name}-${var.environment_name}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_D2als_v6"
  admin_username                  = "localadmin"
  admin_password                  = var.admin_pass
  disable_password_authentication = false
  admin_ssh_key {
    username   = "localadmin"
    public_key = tls_private_key.ssh_key.public_key_openssh
  }
  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  network_interface_ids = [
    azurerm_network_interface.nic_wan.id,
    azurerm_network_interface.nic_lan.id
  ]

  source_image_reference {
    publisher = "fortinet"
    offer     = "fortinet_fortigate-vm"
    sku       = "fortinet_fg-vm_payg_76_g2"
    version   = "latest"
  }

  plan {
    name      = "fortinet_fg-vm_payg_76_g2"
    publisher = "fortinet"
    product   = "fortinet_fortigate-vm"
  }
}
