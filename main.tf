
module "azure_resources" {
  source           = "./modules/azure"
  location         = var.location
  environment_name = var.environment_name
  application_name = var.application_name
  admin_username   = var.admin_username
  admin_pass       = var.admin_pass
  alert_email      = var.alert_email
}

module "fortinet_resources" {
  source            = "./modules/fortinet"
  vpn_user_local    = var.vpn_user_local
  fortios_api_token = var.fortios_api_token
  admin_pass        = var.admin_pass
  vpn_preshared_key = var.vpn_preshared_key
  admin_username    = var.admin_username
  depends_on        = [module.azure_resources]
}


