variable "application_name" {
  type = string
}
variable "environment_name" {
  type = string
}
variable "location" {
  type = string
}
variable "admin_username" {
  type = string
}
variable "admin_pass" {
  type      = string
  sensitive = true
}
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
variable "alert_email" {
  type = string
}
