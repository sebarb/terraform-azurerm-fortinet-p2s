resource "azurerm_monitor_metric_alert" "fortigate_cpu" {
  name                = "alert-fortigate-high-cpu"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_linux_virtual_machine.vm_fortigate.id]

  description = "FortiGate CPU usage exceeds 80% for 5 minutes."

  severity    = 2
  enabled     = true
  frequency   = "PT1M"
  window_size = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
  action {
    action_group_id = azurerm_monitor_action_group.fortigate_alerts.id
  }
}
resource "azurerm_monitor_action_group" "fortigate_alerts" {
  name                = "ag-fortigate-alerts"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "FGTAlerts"

  email_receiver {
    name                    = "admin-email"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}
resource "azurerm_monitor_metric_alert" "fortigate_availability" {
  name                = "alert-fortigate-unavailable"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_linux_virtual_machine.vm_fortigate.id]

  description = "FortiGate VM availability dropped below 1."
  severity    = 1
  enabled     = true

  frequency   = "PT1M"
  window_size = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "VmAvailabilityMetric"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.fortigate_alerts.id
  }
}
