# Plan-time tests for the module. The azurerm provider is mocked, so no credentials, no
# features block, and no cloud calls are needed:
#   terraform init -backend=false && terraform test

mock_provider "azurerm" {}

variables {
  network_security_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001/providers/Microsoft.Network/networkSecurityGroups/nsg-ldo-uks-tst-001"

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
    }
  }
}

run "adds_rules_to_existing_nsg" {
  command = plan

  assert {
    condition     = length(azurerm_network_security_rule.this) == 1
    error_message = "One rule should be created from security_rules."
  }

  assert {
    condition     = azurerm_network_security_rule.this["AllowHttpsInbound"].network_security_group_name == "nsg-ldo-uks-tst-001"
    error_message = "The rule should target the NSG name parsed from network_security_group_id."
  }

  assert {
    condition     = output.resource_group_name == "rg-ldo-uks-tst-001"
    error_message = "resource_group_name should be parsed from network_security_group_id."
  }
}

run "rejects_non_nsg_id" {
  command = plan

  variables {
    network_security_group_id = "/subscriptions/0000/resourceGroups/rg-ldo-uks-tst-001"
  }

  expect_failures = [var.network_security_group_id]
}

run "rejects_priority_out_of_range" {
  command = plan

  variables {
    security_rules = {
      "bad" = {
        priority                   = 99
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    }
  }

  expect_failures = [var.security_rules]
}

run "rejects_invalid_access" {
  command = plan

  variables {
    security_rules = {
      "bad" = {
        priority                   = 300
        direction                  = "Inbound"
        access                     = "Permit"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    }
  }

  expect_failures = [var.security_rules]
}
