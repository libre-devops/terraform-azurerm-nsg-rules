locals {
  location = lookup(var.regions, var.loc, "uksouth")
  rg_name  = "rg-${var.short}-${var.loc}-${terraform.workspace}-002"
  nsg_name = "nsg-${var.short}-${var.loc}-${terraform.workspace}-002"
  asg_name = "asg-${var.short}-${var.loc}-${terraform.workspace}-002"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  environment     = "prd"
  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
  additional_tags = { Application = "terraform-azurerm-nsg-rules" }
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

# An application security group so a rule can target a workload by ASG rather than by address.
resource "azurerm_application_security_group" "this" {
  resource_group_name = module.rg.names[local.rg_name]
  location            = local.location
  tags                = module.tags.tags

  name = local.asg_name
}

# A centrally-managed NSG with its own secure default rules (priorities 4020 to 4096).
module "nsg" {
  source  = "libre-devops/nsg/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  name = local.nsg_name
}

# Complete call: layer several workload rules onto the existing NSG. Priorities (200 to 220) are
# chosen not to collide with the NSG's own default rules, and the rules exercise the fuller surface
# (a plural destination_port_ranges and an application security group destination).
module "nsg_rules" {
  source = "../../"

  network_security_group_id = module.nsg.id

  security_rules = {
    "AllowHttpsInbound" = {
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
      description                = "Allow HTTPS from within the virtual network."
    }
    "AllowWebToAsgInbound" = {
      priority                                   = 210
      direction                                  = "Inbound"
      access                                     = "Allow"
      protocol                                   = "Tcp"
      source_port_range                          = "*"
      destination_port_ranges                    = ["80", "443", "8080"]
      source_address_prefix                      = "VirtualNetwork"
      destination_application_security_group_ids = [azurerm_application_security_group.this.id]
      description                                = "Allow web ports to the application security group."
    }
    "DenySshInbound" = {
      priority                   = 220
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Explicitly deny inbound SSH."
    }
  }
}
