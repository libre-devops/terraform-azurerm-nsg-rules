variable "network_security_group_id" {
  description = "Resource id of the EXISTING network security group to add rules to. The NSG name, resource group, and subscription are parsed from it (pass the nsg module's id output). This module does not create the NSG."
  type        = string

  validation {
    condition     = try(provider::azurerm::parse_resource_id(var.network_security_group_id).resource_type, "") == "networkSecurityGroups"
    error_message = "network_security_group_id must be a network security group id of the form /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/networkSecurityGroups/<name>."
  }
}

variable "security_rules" {
  description = "The NSG rules to add to the existing NSG, keyed by rule name. Each rule needs priority (100 to 4096, unique within the NSG including rules defined elsewhere on it), direction (Inbound/Outbound), access (Allow/Deny), and protocol (Tcp/Udp/Icmp/Esp/Ah/*); set exactly one of the singular or plural form for each of source_port, destination_port, source_address, and destination_address."
  type = map(object({
    priority                                   = number
    direction                                  = string
    access                                     = string
    protocol                                   = string
    description                                = optional(string)
    source_port_range                          = optional(string)
    source_port_ranges                         = optional(list(string))
    destination_port_range                     = optional(string)
    destination_port_ranges                    = optional(list(string))
    source_address_prefix                      = optional(string)
    source_address_prefixes                    = optional(list(string))
    destination_address_prefix                 = optional(string)
    destination_address_prefixes               = optional(list(string))
    source_application_security_group_ids      = optional(list(string))
    destination_application_security_group_ids = optional(list(string))
  }))
  default = {}

  validation {
    condition     = alltrue([for r in values(var.security_rules) : r.priority >= 100 && r.priority <= 4096])
    error_message = "Each rule priority must be between 100 and 4096."
  }

  validation {
    condition     = alltrue([for r in values(var.security_rules) : contains(["Inbound", "Outbound"], r.direction)])
    error_message = "Each rule direction must be Inbound or Outbound."
  }

  validation {
    condition     = alltrue([for r in values(var.security_rules) : contains(["Allow", "Deny"], r.access)])
    error_message = "Each rule access must be Allow or Deny."
  }

  validation {
    condition     = alltrue([for r in values(var.security_rules) : contains(["Tcp", "Udp", "Icmp", "Esp", "Ah", "*"], r.protocol)])
    error_message = "Each rule protocol must be one of Tcp, Udp, Icmp, Esp, Ah, or *."
  }
}
