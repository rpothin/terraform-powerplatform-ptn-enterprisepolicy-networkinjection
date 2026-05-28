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
- `enterprisePoliciesPreview` preview feature registered in the target Azure subscription (required for the `Microsoft.PowerPlatform/enterprisePolicies` ARM resource):
  ```bash
  az feature register --namespace Microsoft.PowerPlatform --name enterprisePoliciesPreview
  # Wait for state to become "Registered" before applying
  az feature show --namespace Microsoft.PowerPlatform --name enterprisePoliciesPreview --query properties.state
  ```
  > **Note:** This module uses the `Microsoft.PowerPlatform/enterprisePolicies@2020-10-30-preview` ARM API, which is the only available version. The preview nature of the API is an upstream constraint — no GA version exists at this time.
- OIDC-based authentication configured for all three providers (`azapi`, `azurerm`, `powerplatform`)

## Important: NSG outbound requirements

When `create_network_infrastructure = true`, this module creates NSGs with a `DenyAllOutBound` rule at priority 4096. **This will block Power Platform VNet injection from functioning** because the PP service requires outbound HTTPS connectivity to Microsoft service endpoints.

You must provide the required outbound allow rules via `nsg_additional_rules` before applying the module. See the [complete example](examples/complete/) for a starting point and the [Power Platform VNet injection documentation](https://learn.microsoft.com/en-us/power-platform/admin/vnet-support-overview) for the current list of required endpoints.

## Private endpoint subnet security

When `create_network_infrastructure = true`, PE subnets are protected by a dedicated NSG that allows only intra-VNet traffic by default (same deny-all base rules as the PP-delegated NSG). Unlike the PP-delegated NSG, **no mandatory outbound rules are required** — private endpoints are passive receivers and do not initiate connections.

NSG enforcement is explicitly enabled on PE subnets (`private_endpoint_network_policies = "NetworkSecurityGroupEnabled"`), which is required for Azure to enforce the NSG on private endpoint NICs. To add extra allow/deny rules, use the `nsg_pe_additional_rules` variable.

## VNet peering and cross-region PE access

When both VNets are created, the module peers them with `allow_forwarded_traffic = true` on both directions. This is required when a private endpoint exists in only one region's subnet (a common scenario due to private DNS zone constraints) and workloads in the other region need to reach it across the peering link. Private DNS zones are linked to both VNets, so DNS resolution works from either region.

> **Note on hub-and-spoke:** The module creates direct primary-to-failover peering only. For hub-and-spoke architectures with an NVA or Azure Firewall in a hub, configure additional peerings manually and set `allow_gateway_transit` / `use_remote_gateways` as needed on those external peerings.

