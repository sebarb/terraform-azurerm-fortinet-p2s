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
//Create Linux VM workload
resource "azurerm_linux_virtual_machine" "vm_workload" {
  name                            = "vm-${var.application_name}-${var.environment_name}-workload"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_B1s"
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
