variable "fortios_api_token" {
  type      = string
  sensitive = true
}
variable "vpn_preshared_key" {
  type      = string
  sensitive = true
}
variable "vpn_user_local" {
  type = string
}
variable "admin_username" {
  type = string
}
variable "admin_pass" {
  type      = string
  sensitive = true
}
