########################################
# main.tf — Simple Windows VM POC on Azure
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
  address_space       = [var.address_space]
  tags                = var.tags
}

resource "azurerm_subnet" "subnet" {
  name                 = local.snet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_prefix]
}

# 3) NSG — allow RDP only from your CIDR
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

# 4) Public IP
resource "azurerm_public_ip" "pip" {
  name                = local.pip_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags
}

# 5) NIC
resource "azurerm_network_interface" "nic" {
  name                = local.nic_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# 6) Windows VM
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

  enable_automatic_updates = true
  patch_mode               = "AutomaticByOS"
  boot_diagnostics { storage_account_uri = null }
}
