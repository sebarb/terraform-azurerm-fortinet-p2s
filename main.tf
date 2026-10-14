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
  source_address_prefix       = "*"
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
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["443"]
}

resource "azurerm_subnet_network_security_group_association" "wan_nsg" {
  subnet_id                 = azurerm_subnet.subnet_wan.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

//Create Linux VM workload
resource "azurerm_linux_virtual_machine" "vm_workload" {
  name                            = "vm-${var.application_name}-${var.environment_name}-workload"
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
  name                            = "vm-${var.application_name}-${var.environment_name}-nva"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_D2als_v6"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_pass
  disable_password_authentication = false
  admin_ssh_key {
    username   = var.admin_username
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


resource "fortios_firewall_address" "workload_subnet" {
  name                 = "workload-subnet"
  subnet               = "172.16.3.0 255.255.255.0"
  associated_interface = "port2"
  depends_on           = [azurerm_linux_virtual_machine.vm_fortigate]
}

resource "fortios_router_static" "static_route_workload" {
  seq_num    = 1
  dst        = "172.16.3.0 255.255.255.0"
  gateway    = "172.16.2.1"
  device     = "port2"
  depends_on = [azurerm_linux_virtual_machine.vm_fortigate]
}

resource "fortios_firewall_policy" "snat_policy" {
  policyid = 1
  name     = "snat"
  srcintf {
    name = "port2"
  }
  dstintf {
    name = "port1"
  }
  action   = "accept"
  schedule = "always"
  nat      = "enable"
  service {
    name = "ALL"
  }
  srcaddr {
    name = fortios_firewall_address.workload_subnet.name
  }
  dstaddr {
    name = "all"
  }
  depends_on = [azurerm_linux_virtual_machine.vm_fortigate, azurerm_public_ip.public_ip]
}

resource "fortios_user_local" "vpn_user" {
  name       = var.vpn_user_local
  type       = "password"
  passwd     = var.admin_pass
  status     = "enable"
  two_factor = "disable"
  depends_on = [azurerm_linux_virtual_machine.vm_fortigate, azurerm_public_ip.public_ip]
}

resource "fortios_user_group" "remote_group" {
  group_type   = "firewall"
  max_accounts = 0

  name = "remote_group"

  member {
    name = var.vpn_user_local
  }
  depends_on = [azurerm_linux_virtual_machine.vm_fortigate, fortios_user_local.vpn_user]
}

resource "fortios_vpnipsec_phase1interface" "vpn_phase1" {
  name = "phase1"
  type = "dynamic"
  //remote_gw          = azurerm_public_ip.public_ip.ip_address
  ipv4_split_include = fortios_firewall_address.workload_subnet.name
  interface          = "port1"
  authmethod         = "psk"
  psksecret          = var.vpn_preshared_key
  proposal           = "aes256-sha256"
  ike_version        = "2"
  transport          = "udp"
  authusrgrp         = fortios_user_group.remote_group.name
  assign_ip          = "enable"
  assign_ip_from     = "range"
  eap                = "enable"
  ipv4_start_ip      = "10.20.0.10"
  ipv4_end_ip        = "10.20.0.100"
  ipv4_netmask       = "255.255.255.0"
  dhgrp              = "14"
  mode_cfg           = "enable"
  nattraversal       = "enable"
  peertype           = "any"
  eap_identity       = "send-request"
  depends_on         = [fortios_user_group.remote_group, fortios_firewall_address.workload_subnet]
}


resource "fortios_vpnipsec_phase2interface" "vpn_phase2" {
  name          = "phase2"
  phase1name    = fortios_vpnipsec_phase1interface.vpn_phase1.name
  proposal      = "aes256-sha256"
  encapsulation = "tunnel-mode"
  src_subnet    = "0.0.0.0 0.0.0.0"
  dst_subnet    = "0.0.0.0 0.0.0.0"
  pfs           = "enable"
  dhgrp         = "14"
  depends_on    = [fortios_vpnipsec_phase1interface.vpn_phase1]
}

resource "fortios_firewall_policy" "vpn_to_workload" {
  policyid = 20
  name     = "vpn-to-workload"

  srcintf {
    name = fortios_vpnipsec_phase1interface.vpn_phase1.name
  }

  dstintf {
    name = "port2"
  }

  srcaddr {
    name = "all"
  }

  dstaddr {
    name = fortios_firewall_address.workload_subnet.name
  }

  service {
    name = "SSH"
  }

  action     = "accept"
  schedule   = "always"
  nat        = "disable"
  logtraffic = "all"
  depends_on = [fortios_firewall_address.workload_subnet, fortios_vpnipsec_phase1interface.vpn_phase1]
}

