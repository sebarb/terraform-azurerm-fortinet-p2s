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
  //depends_on         = [fortios_user_group.remote_group, fortios_firewall_address.workload_subnet]
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
  //depends_on    = [fortios_vpnipsec_phase1interface.vpn_phase1]
}
