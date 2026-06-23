############################################
# Public IP (optional)
############################################
resource "azurerm_public_ip" "pip" {
  count               = var.create_public_ip ? 1 : 0
  name                = "${var.vm_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

############################################
# Network Interface
############################################
resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.pip[0].id : null
  }
}

############################################
# Windows Virtual Machine
############################################
resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.vm_name
  computer_name       = substr(replace(var.vm_name, "[^a-zA-Z0-9]", ""), 0, 15)
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size

  admin_username = var.admin_username
  admin_password = var.admin_password

  network_interface_ids = [azurerm_network_interface.nic.id]

  patch_mode                 = "AutomaticByOS"
  encryption_at_host_enabled = true

  tags = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 127
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {}
}

############################################
# Azure Monitor Agent (AMA)
############################################
resource "azurerm_virtual_machine_extension" "ama" {
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  tags                       = var.tags
}

############################################
# Alerting (uses alert_email properly ✅)
############################################

# Action Group (email notifications)
resource "azurerm_monitor_action_group" "vm_alerts" {
  name                = "${var.vm_name}-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "alerts"

  email_receiver {
    name          = "admin"
    email_address = var.alert_email
  }

  tags = var.tags
}

# CPU Alert
resource "azurerm_monitor_metric_alert" "cpu_alert" {
  name                = "${var.vm_name}-cpu-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_windows_virtual_machine.vm.id]
  description         = "High CPU usage alert"

  severity = 2
  frequency   = "PT5M"
  window_size = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.vm_alerts.id
  }

  tags = var.tags
}