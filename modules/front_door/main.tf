########################################
# Azure Front Door Premium
# WAF (OWASP + Bot Manager managed rules) = L7 DDoS protection
# CDN caching rules on the route
########################################

resource "azurerm_cdn_frontdoor_profile" "afd" {
  name                = "${var.project_name}-afd"
  resource_group_name = var.resource_group_name
  sku_name            = "Premium_AzureFrontDoor"
  tags                = var.tags
}

# WAF policy — Prevention mode blocks malicious requests at the edge
resource "azurerm_cdn_frontdoor_firewall_policy" "waf" {
  name                = "${replace(var.project_name, "-", "")}wafpolicy"
  resource_group_name = var.resource_group_name
  sku_name            = azurerm_cdn_frontdoor_profile.afd.sku_name
  mode                = "Prevention"
  tags                = var.tags

  # OWASP core ruleset
  managed_rule {
    type    = "Microsoft_DefaultRuleSet"
    version = "2.1"
    action  = "Block"
  }

  # Bot manager ruleset
  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }
}

resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  name                     = "${var.project_name}-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id
  tags                     = var.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "og" {
  name                     = "${var.project_name}-og"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 30
  }
}

resource "azurerm_cdn_frontdoor_origin" "origin" {
  name                           = "${var.project_name}-origin"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.og.id
  enabled                        = true
  host_name                      = var.origin_host_name
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = var.origin_host_name
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = false # TODO: Enable after adding HTTPS listener + TLS cert to App Gateway
}

# Route with CDN caching
resource "azurerm_cdn_frontdoor_route" "route" {
  name                          = "${var.project_name}-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.og.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.origin.id]
  enabled                       = true
  forwarding_protocol           = "HttpOnly"   # TLS terminates at Front Door; App GW listens HTTP/80
  https_redirect_enabled        = true
  patterns_to_match             = ["/*"]
  supported_protocols           = ["Http", "Https"]

  cache {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = true
    content_types_to_compress = [
      "text/html",
      "text/javascript",
      "text/css",
      "application/javascript",
      "application/json",
      "image/svg+xml",
    ]
  }
}

# Associate WAF policy with the Front Door endpoint
resource "azurerm_cdn_frontdoor_security_policy" "waf_assoc" {
  name                     = "${var.project_name}-security-policy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.afd.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.waf.id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.endpoint.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}
