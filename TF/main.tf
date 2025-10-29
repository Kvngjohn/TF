# Resource Group (uses project_name + location)
resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-rg"
  location = var.location
}

# VNet + Subnet
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project_name}-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.address_space]
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.project_name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_prefix]
}

# Public IP (required if you want RDP over Internet)
resource "azurerm_public_ip" "pip" {
  name                = "${var.project_name}-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"   # Standard requires Static
  sku                 = "Standard"
}

# NIC (attach Subnet + Public IP)
resource "azurerm_network_interface" "nic" {
  name                = "${var.project_name}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.project_name}-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# Windows VM (use the modern resource)
resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size

  admin_username = var.admin_username
  admin_password = var.admin_password

  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 127
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  enable_automatic_updates = true
  patch_mode               = "AutomaticByOS"

  # keep POC simple: disable storage-account boot diagnostics
  boot_diagnostics { storage_account_uri = null }

  tags = var.tags
}

# Helpful outputs
output "public_ip" {
  value       = azurerm_public_ip.pip.ip_address
  description = "RDP to this address on 3389"
}

output "rdp_hint" {
  value       = "mstsc /v:${azurerm_public_ip.pip.ip_address}:3389"
  description = "Quick RDP command"
}
