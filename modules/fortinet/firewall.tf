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
  //depends_on = [azurerm_linux_virtual_machine.vm_fortigate, azurerm_public_ip.public_ip]
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
  //depends_on = [fortios_firewall_address.workload_subnet, fortios_vpnipsec_phase1interface.vpn_phase1]
}

