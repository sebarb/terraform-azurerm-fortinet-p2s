resource "fortios_user_local" "vpn_user" {
  name       = var.vpn_user_local
  type       = "password"
  passwd     = var.admin_pass
  status     = "enable"
  two_factor = "disable"
  //depends_on = [azurerm_linux_virtual_machine.vm_fortigate, azurerm_public_ip.public_ip]
}
resource "fortios_user_group" "remote_group" {
  group_type   = "firewall"
  max_accounts = 0

  name = "remote_group"

  member {
    name = var.vpn_user_local
  }
  //depends_on = [azurerm_linux_virtual_machine.vm_fortigate, fortios_user_local.vpn_user]
  depends_on = [fortios_user_local.vpn_user]
}
