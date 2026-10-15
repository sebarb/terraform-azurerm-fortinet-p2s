resource "fortios_router_static" "static_route_workload" {
  seq_num = 1
  dst     = "172.16.3.0 255.255.255.0"
  gateway = "172.16.2.1"
  device  = "port2"
}
