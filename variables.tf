variable "application_name" {
  type = string
}
variable "environment_name" {
  type = string
}
variable "location" {
  type = string
}
variable "admin_pass" {
  sensitive = true
}
