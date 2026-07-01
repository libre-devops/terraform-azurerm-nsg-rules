<!--
  Keep the title and badges OUTSIDE the centered <div>: the Terraform Registry's markdown renderer
  does not parse markdown inside an HTML block, so a # heading or [![badge]] in the div renders as
  literal text on the registry. Only the logo (HTML) goes in the div.
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="300">
    </picture>
  </a>
</div>

# Terraform Azure Network Security Group Rules

Adds rules to an existing Azure network security group, without creating the NSG.

[![CI](https://github.com/libre-devops/terraform-azurerm-nsg-rules/actions/workflows/ci.yml/badge.svg)](https://github.com/libre-devops/terraform-azurerm-nsg-rules/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/libre-devops/terraform-azurerm-nsg-rules?sort=semver&label=release)](https://github.com/libre-devops/terraform-azurerm-nsg-rules/releases/latest)
[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)
[![License](https://img.shields.io/github/license/libre-devops/terraform-azurerm-nsg-rules)](./LICENSE)

---

## Overview

Adds `security_rules` (keyed by name) to an **existing** network security group, passed by id, without
creating the NSG. It is the counterpart to the [`nsg`](https://registry.terraform.io/modules/libre-devops/nsg/azurerm)
module, mirroring how the `subnet` module adds subnets to a vnet the `network` module owns. This works
because the `nsg` module manages its rules as **standalone** `azurerm_network_security_rule` resources
(non-authoritative): rules this module adds coexist with the NSG's own rather than being clobbered.
Keep priorities from colliding with rules defined elsewhere on the same NSG. Useful for layering
workload- or team-owned rules onto a shared, centrally-managed NSG.

## Usage

```hcl
module "nsg_rules" {
  source  = "libre-devops/nsg-rules/azurerm"
  version = "~> 4.0"

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
    }
  }
}
```

## Examples

- [`examples/minimal`](./examples/minimal) - creates an NSG with the `nsg` module, then adds a single
  rule to it with this module.
- [`examples/complete`](./examples/complete) - adds several rules (including one targeting an
  application security group) to an NSG created by the `nsg` module, with priorities chosen not to
  collide with the NSG's own default rules.

## Developing

Local work needs **PowerShell 7+** and **[`just`](https://github.com/casey/just)**, because the recipes
wrap the [LibreDevOpsHelpers](https://www.powershellgallery.com/packages/LibreDevOpsHelpers)
PowerShell module (the same engine the `libre-devops/terraform-azure` action runs in CI). Install
just with `brew install just`, or `uv tool add rust-just` then `uv run just <recipe>`.

Run `just` to list recipes: `just update-ldo-pwsh` (install or force-update LibreDevOpsHelpers from
PSGallery), `just validate`, `just scan` (Trivy only), `just pwsh-analyze` (PSScriptAnalyzer only),
`just plan`, `just apply`, `just destroy`, `just e2e`, `just test`, and `just docs` (the
plan/apply/destroy recipes mirror the action, including the storage firewall dance; `just e2e`
applies an example then always destroys it, defaulting to `minimal`, so nothing is left running).
Releasing is also `just`:
`just increment-release [patch|minor|major]` bumps, tags, and publishes a GitHub release, and the
Terraform Registry picks up the tag.

## Security scan exceptions

This module is scanned with [Trivy](https://github.com/aquasecurity/trivy); HIGH and CRITICAL
findings fail the build. Any waiver is a deliberate, reviewed decision, never a way to quiet a
finding that should be fixed. Waivers live in [`.trivyignore.yaml`](./.trivyignore.yaml) (the
machine-applied source of truth, passed to Trivy with `--ignorefile`) and are mirrored in the table
below so the reason is auditable.

| Trivy ID | Resource | Finding | Justification |
|----------|----------|---------|---------------|
| _None_   |          |         |               |

To add an exception: add an entry to `.trivyignore.yaml` (`id`, optional `paths` to scope it, and a
`statement` recording why), then add a matching row here. Where the finding is out of this module's
scope, point the justification at the Libre DevOps module that does address it (for example the
private-endpoint module). Both the file and this table are reviewed in the pull request.

## Reference

The Requirements, Providers, Inputs, Outputs, and Resources below are generated by `terraform-docs`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.0.0, < 5.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_network_security_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_network_security_group_id"></a> [network\_security\_group\_id](#input\_network\_security\_group\_id) | Resource id of the EXISTING network security group to add rules to. The NSG name, resource group, and subscription are parsed from it (pass the nsg module's id output). This module does not create the NSG. | `string` | n/a | yes |
| <a name="input_security_rules"></a> [security\_rules](#input\_security\_rules) | The NSG rules to add to the existing NSG, keyed by rule name. Each rule needs priority (100 to 4096, unique within the NSG including rules defined elsewhere on it), direction (Inbound/Outbound), access (Allow/Deny), and protocol (Tcp/Udp/Icmp/Esp/Ah/*); set exactly one of the singular or plural form for each of source\_port, destination\_port, source\_address, and destination\_address. | <pre>map(object({<br/>    priority                                   = number<br/>    direction                                  = string<br/>    access                                     = string<br/>    protocol                                   = string<br/>    description                                = optional(string)<br/>    source_port_range                          = optional(string)<br/>    source_port_ranges                         = optional(list(string))<br/>    destination_port_range                     = optional(string)<br/>    destination_port_ranges                    = optional(list(string))<br/>    source_address_prefix                      = optional(string)<br/>    source_address_prefixes                    = optional(list(string))<br/>    destination_address_prefix                 = optional(string)<br/>    destination_address_prefixes               = optional(list(string))<br/>    source_application_security_group_ids      = optional(list(string))<br/>    destination_application_security_group_ids = optional(list(string))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_network_security_group_id"></a> [network\_security\_group\_id](#output\_network\_security\_group\_id) | The id of the NSG the rules were added to (echoed from the input). |
| <a name="output_network_security_group_name"></a> [network\_security\_group\_name](#output\_network\_security\_group\_name) | NSG name parsed from network\_security\_group\_id. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Resource group name parsed from network\_security\_group\_id. |
| <a name="output_security_rule_ids"></a> [security\_rule\_ids](#output\_security\_rule\_ids) | Map of rule name to network security rule id (the rules this module added). |
| <a name="output_security_rules"></a> [security\_rules](#output\_security\_rules) | The rules this module added, keyed by rule name. |
| <a name="output_subscription_id"></a> [subscription\_id](#output\_subscription\_id) | Subscription id parsed from network\_security\_group\_id. |
<!-- END_TF_DOCS -->
