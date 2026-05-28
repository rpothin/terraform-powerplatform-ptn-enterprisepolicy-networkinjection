# ptn-enterprisepolicy-networkinjection

[![Terraform Registry](https://img.shields.io/badge/Terraform-Registry-blue.svg)](https://registry.terraform.io/modules/rpothin/ptn-enterprisepolicy-networkinjection/powerplatform/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

This Power Platform Terraform pattern module creates all Azure networking infrastructure required for [Power Platform VNet injection](https://learn.microsoft.com/en-us/power-platform/admin/vnet-support-overview) and links one or more Power Platform environments to a Network Injection enterprise policy.

## What it does

- Creates an Azure `Microsoft.PowerPlatform/enterprisePolicies` (kind=`NetworkInjection`) ARM resource via the `azapi` provider
- Optionally creates primary and failover VNets, PP-delegated subnets, private-endpoint subnets, NSGs, and VNet peering
- Optionally creates private DNS zones and links them to both VNets
- Validates that all linked environments are in the same Power Platform region as the enterprise policy
- Links each environment to the enterprise policy using the `powerplatform_enterprise_policy` resource

## Prerequisites

- Power Platform environments must be of **Managed** type before being linked
- Azure subscription with permissions to create networking and `Microsoft.PowerPlatform` resources
- `Microsoft.PowerPlatform` resource provider registered in the target Azure subscription:
  ```bash
  az provider register --namespace Microsoft.PowerPlatform
  ```
- OIDC-based authentication configured for all three providers (`azapi`, `azurerm`, `powerplatform`)

## Important: NSG outbound requirements

When `create_network_infrastructure = true`, this module creates NSGs with a `DenyAllOutBound` rule at priority 4096. **This will block Power Platform VNet injection from functioning** because the PP service requires outbound HTTPS connectivity to Microsoft service endpoints.

You must provide the required outbound allow rules via `nsg_additional_rules` before applying the module. See the [complete example](examples/complete/) for a starting point and the [Power Platform VNet injection documentation](https://learn.microsoft.com/en-us/power-platform/admin/vnet-support-overview) for the current list of required endpoints.

> **Note on hub-and-spoke:** If your VNets are peered to a hub containing an NVA or Azure Firewall, be aware that VNet peering does not set `allow_forwarded_traffic` by default. Forwarded traffic from a hub will be dropped unless `allow_forwarded_traffic = true` is configured on the peering. This module creates direct primary-to-failover peering only; for hub-and-spoke architectures you will need to configure additional peerings manually.

