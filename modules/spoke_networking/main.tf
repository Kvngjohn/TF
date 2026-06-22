########################################
# Spoke VNet — App, Data, and Storage subnets
# Peered to Hub VNet; all internet egress via Firewall UDR
########################################

resource "azurerm_virtual_network" "spoke" {
  name                = "${var.project_name}-spoke-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.spoke_address_space]
  tags                = var.tags
}

# App subnet — Windows VMs
resource "azurerm_subnet" "app" {
  name                 = "${var.project_name}-app-snet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.app_subnet_prefix]
}

# Data subnet — private endpoints for SQL servers
resource "azurerm_subnet" "data" {
  name                 = "${var.project_name}-data-snet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.data_subnet_prefix]

  # Disable network policies so private endpoint NICs can function
  private_endpoint_network_policies = "Disabled"
}

# Storage subnet — private endpoint for storage account
resource "azurerm_subnet" "storage" {
  name                 = "${var.project_name}-storage-snet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.storage_subnet_prefix]

  private_endpoint_network_policies = "Disabled"
}

# App Gateway subnet — must not have UDR or conflicting NSG rules.
# The app_gateway module attaches its own NSG to this subnet.
resource "azurerm_subnet" "appgw" {
  name                 = "${var.project_name}-appgw-snet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.appgw_subnet_prefix]
}

# NSG for app subnet: allow RDP from trusted CIDR, deny all internet inbound
resource "azurerm_network_security_group" "app_nsg" {
  name                = "${var.project_name}-app-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow-RDP-From-Trusted"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.allow_rdp_from_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-Internet-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "app_assoc" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

# UDR associations: route internet traffic through hub Firewall
resource "azurerm_subnet_route_table_association" "app_udr" {
  subnet_id      = azurerm_subnet.app.id
  route_table_id = var.spoke_udr_id
}

resource "azurerm_subnet_route_table_association" "data_udr" {
  subnet_id      = azurerm_subnet.data.id
  route_table_id = var.spoke_udr_id
}

# VNet Peerings (both directions required)
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "hub-to-spoke"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = var.hub_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "spoke-to-hub"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = var.hub_vnet_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}
