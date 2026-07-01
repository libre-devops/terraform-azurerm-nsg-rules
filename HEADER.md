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
