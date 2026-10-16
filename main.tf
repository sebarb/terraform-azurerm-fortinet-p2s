
module "azure" {
  source           = "./modules/azure"
  location         = var.location
  environment_name = var.environment_name
  application_name = var.application_name
  admin_username   = var.admin_username
  admin_pass       = var.admin_pass
  alert_email      = var.alert_email
  local_IP         = var.local_IP
}


module "fortinet" {
  source            = "./modules/fortinet"
  vpn_user_local    = var.vpn_user_local
  admin_pass        = var.admin_pass
  vpn_preshared_key = var.vpn_preshared_key
  depends_on        = [module.azure]
}

