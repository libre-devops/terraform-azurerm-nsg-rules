# Adds rules to an EXISTING network security group without creating the NSG (the counterpart to the
# nsg module, mirroring how the subnet module adds subnets to an existing vnet). Rules are standalone
# azurerm_network_security_rule resources keyed by rule name; because the nsg module also uses
# standalone (non-authoritative) rules, this module can layer rules onto an NSG it manages without the
# two clobbering each other. Just keep priorities from colliding with rules defined elsewhere on the
# same NSG. The NSG is passed by id and parsed for its name, resource group, and subscription.
locals {
  nsg                         = provider::azurerm::parse_resource_id(var.network_security_group_id)
  resource_group_name         = local.nsg.resource_group_name
  network_security_group_name = local.nsg.resource_name
}

resource "azurerm_network_security_rule" "this" {
  for_each = var.security_rules

  resource_group_name         = local.resource_group_name
  network_security_group_name = local.network_security_group_name

  name                                       = each.key
  priority                                   = each.value.priority
  direction                                  = each.value.direction
  access                                     = each.value.access
  protocol                                   = each.value.protocol
  description                                = each.value.description
  source_port_range                          = each.value.source_port_range
  source_port_ranges                         = each.value.source_port_ranges
  destination_port_range                     = each.value.destination_port_range
  destination_port_ranges                    = each.value.destination_port_ranges
  source_address_prefix                      = each.value.source_address_prefix
  source_address_prefixes                    = each.value.source_address_prefixes
  destination_address_prefix                 = each.value.destination_address_prefix
  destination_address_prefixes               = each.value.destination_address_prefixes
  source_application_security_group_ids      = each.value.source_application_security_group_ids
  destination_application_security_group_ids = each.value.destination_application_security_group_ids
}
