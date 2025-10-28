########################################
# main.tf — Simple Win VM POC on Azure
########################################

locals {
  rg_name   = "${var.project_name}-rg"
  vnet_name = "${var.project_name}-vnet"
  snet_name = "${var.project_name}-snet"
  nsg_name  = "${var.project_name}-nsg"
  pip_name  = "${var.project_name}-pip"
  nic_name  = "${var.project_name}-nic"
  vm_name   = "${var.project_name}-winvm01"
}

# 1) Resource Group
resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
  tags     = var.tags
}

# 2) VNet + Subnet
resource "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  # var.address_space is a single CIDR; wrap as a list
  address_space = [var.address_space]

  tags = var.tags
}

resource "azurerm_subnet" "subnet" {
  name                 = local.snet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_prefix]
}

# 3) NSG — allow RDP only from your CIDR, then implicitly deny the rest
# (No explicit "deny all" needed; Azure NSGs deny unmatched traffic.)
resource "azurerm_network_security_group" "nsg" {
  name                = local.nsg_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "Allow-RDP-From-YourIP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.allow_rdp_from_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# 4) Public IP (POC convenience; for production prefer Private + Bastion/Jumpbox)

resource "azurerm_public_ip" "pip" {
  name                = local.pip_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  sku                 = "Standard"
  allocation_method   = "Static"   # <-- required for Standard
  tags                = var.tags
}

# 5) NIC — use Dynamic private IP to avoid validation for missing static IP value
resource "azurerm_network_interface" "nic" {
  name                = local.nic_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"    # <— IMPORTANT: avoid static without setting private_ip_address
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# 6) Windows VM (2022 Azure Edition)
resource "azurerm_windows_virtual_machine" "vm" {
  name                = local.vm_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size

  admin_username = var.admin_username
  admin_password = var.admin_password

  network_interface_ids = [azurerm_network_interface.nic.id]
  tags                  = var.tags

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

  # Optional quality-of-life flags
  enable_automatic_updates = true
  patch_mode               = "AutomaticByOS"

  # For a POC you can omit this block and let managed boot diagnostics enable automatically,
  # or leave it disabled as below to avoid creating a storage account.
  # boot_diagnostics {}                      # enable managed boot diagnostics
  # OR disable explicitly:
  boot_diagnostics { storage_account_uri = null }
}

# 7) Handy outputs
output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "public_ip" {
  value = azurerm_public_ip.pip.ip_address
}

output "rdp_hint" {
  value = "mstsc /v:${azurerm_public_ip.pip.ip_address}:3389"
}
