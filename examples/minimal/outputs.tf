output "added_rule_ids" {
  description = "The ids of the rules added to the NSG by the nsg-rules module."
  value       = module.nsg_rules.security_rule_ids
}

output "nsg_id" {
  description = "The id of the network security group the rules were added to."
  value       = module.nsg.id
}
