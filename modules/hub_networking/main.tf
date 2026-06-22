########################################
# Hub VNet + Azure Firewall
# All spoke internet traffic is force-tunnelled through the Firewall.
########################################

resource "azurerm_virtual_network" "hub" {
  name                = "${var.project_name}-hub-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.hub_address_space]
  tags                = var.tags
}

# Required subnet name for Azure Firewall
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.firewall_subnet_prefix]
}

resource "azurerm_subnet" "hub_mgmt" {
  name                 = "${var.project_name}-hub-mgmt-snet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub_mgmt_subnet_prefix]
}

# Azure Bastion — must be named exactly "AzureBastionSubnet", minimum /26
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.bastion_subnet_prefix]
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "${var.project_name}-bastion-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Basic SKU provides browser-based RDP/SSH — upgrade to Standard for
# file copy, native client tunnelling, and multi-hop Bastion.
resource "azurerm_bastion_host" "bastion" {
  name                = "${var.project_name}-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Basic"
  tags                = var.tags

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}

resource "azurerm_public_ip" "firewall_pip" {
  name                = "${var.project_name}-fw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall_policy" "fw_policy" {
  name                = "${var.project_name}-fw-policy"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall" "firewall" {
  name                = "${var.project_name}-firewall"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.fw_policy.id
  tags                = var.tags

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall_pip.id
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "rules" {
  name               = "${var.project_name}-fw-rules"
  firewall_policy_id = azurerm_firewall_policy.fw_policy.id
  priority           = 100

  network_rule_collection {
    name     = "allow-spoke-dns"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "dns-to-azure"
      source_addresses      = [var.spoke_address_space]
      destination_addresses = ["168.63.129.16/32"]
      destination_ports     = ["53"]
      protocols             = ["UDP", "TCP"]
    }
  }

  application_rule_collection {
    name     = "allow-windows-update"
    priority = 200
    action   = "Allow"

    rule {
      name             = "windows-update"
      source_addresses = [var.spoke_address_space]
      destination_fqdns = [
        "*.update.microsoft.com",
        "*.windowsupdate.com",
        "*.download.windowsupdate.com",
      ]
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  application_rule_collection {
    name     = "allow-azure-services"
    priority = 300
    action   = "Allow"

    rule {
      name             = "azure-management-and-monitoring"
      source_addresses = [var.spoke_address_space]
      destination_fqdns = [
        "*.azure-automation.net",
        "*.microsoftonline.com",
        "login.windows.net",
        "*.monitor.azure.com",
        "*.ods.opinsights.azure.com",
        "*.oms.opinsights.azure.com",
        "*.blob.core.windows.net",
        "*.azure-dns.com",
        "*.azureedge.net",
        "management.azure.com",
        "packages.microsoft.com",
      ]
      protocols {
        type = "Https"
        port = 443
      }
    }
  }
}

# Route table: force all spoke internet traffic through Firewall private IP
resource "azurerm_route_table" "spoke_udr" {
  name                          = "${var.project_name}-spoke-udr"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  bgp_route_propagation_enabled = false
  tags                          = var.tags

  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }
}

# Firewall diagnostic settings → Log Analytics
resource "azurerm_monitor_diagnostic_setting" "firewall_diag" {
  name                       = "${var.project_name}-fw-diag"
  target_resource_id         = azurerm_firewall.firewall.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "AzureFirewallApplicationRule" }
  enabled_log { category = "AzureFirewallNetworkRule" }
  enabled_log { category = "AzureFirewallDnsProxy" }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
