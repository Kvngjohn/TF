output "front_door_endpoint_hostname" {
  description = "Front Door endpoint hostname — point your DNS CNAME here"
  value       = azurerm_cdn_frontdoor_endpoint.endpoint.host_name
}

output "front_door_profile_id" {
  value = azurerm_cdn_frontdoor_profile.afd.id
}

output "waf_policy_id" {
  value = azurerm_cdn_frontdoor_firewall_policy.waf.id
}
