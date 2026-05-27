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
- OIDC-based authentication configured for all three providers (`azapi`, `azurerm`, `powerplatform`)

