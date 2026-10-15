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
variable "alert_email" {
  type = string
}
variable "local_IP" {
  description = "Trusted public IPv4 for Fortigate management"
  type        = string
}
