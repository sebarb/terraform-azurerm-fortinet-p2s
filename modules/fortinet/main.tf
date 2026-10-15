resource "fortios_firewall_address" "workload_subnet" {
  name                 = "workload-subnet"
  subnet               = "172.16.3.0 255.255.255.0"
  associated_interface = "port2"

}
