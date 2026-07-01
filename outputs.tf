output "network_security_group_id" {
  description = "The id of the NSG the rules were added to (echoed from the input)."
  value       = var.network_security_group_id
}

output "network_security_group_name" {
  description = "NSG name parsed from network_security_group_id."
  value       = local.network_security_group_name
}

output "resource_group_name" {
  description = "Resource group name parsed from network_security_group_id."
  value       = local.resource_group_name
}

output "security_rule_ids" {
  description = "Map of rule name to network security rule id (the rules this module added)."
  value       = { for k, r in azurerm_network_security_rule.this : k => r.id }
}

output "security_rules" {
  description = "The rules this module added, keyed by rule name."
  value       = azurerm_network_security_rule.this
}

output "subscription_id" {
  description = "Subscription id parsed from network_security_group_id."
  value       = local.nsg.subscription_id
}
