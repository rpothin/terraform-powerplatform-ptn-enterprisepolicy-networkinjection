locals {
  # Map PP region names to ARM location aliases for Microsoft.PowerPlatform/enterprisePolicies.
  # Most PP regions map 1:1, but two differ: unitedkingdom→uk, southamerica→brazil.
  enterprise_policy_arm_location = lookup(
    {
      unitedkingdom = "uk"
      southamerica  = "brazil"
    },
    var.enterprise_policy_location,
    var.enterprise_policy_location
  )

  # ARM body for the enterprise policy resource
  enterprise_policy_body = {
    kind = "NetworkInjection"
    properties = {
      networkInjection = {
        virtualNetworks = [
          {
            id = local.primary_vnet_id
            subnet = {
              name = local.primary_pp_subnet_name
            }
          },
          {
            id = local.failover_vnet_id
            subnet = {
              name = local.failover_pp_subnet_name
            }
          },
        ]
      }
    }
  }

  # Lookup map: environment GUID → environment object (for location validation)
  environments_by_id = {
    for env in data.powerplatform_environments.all.environments : env.id => env
  }

  # Resolved PP-delegated subnet ID and name — failover
  failover_pp_subnet_id   = length(module.failover_vnet) > 0 ? module.failover_vnet[0].subnets["pp"].resource_id : try(var.network_config.failover.subnet_id, "")
  failover_pp_subnet_name = length(module.failover_vnet) > 0 ? module.failover_vnet[0].subnets["pp"].name : try(var.network_config.failover.subnet_name, "")

  # Resolved VNet ID — failover
  failover_vnet_id = length(module.failover_vnet) > 0 ? module.failover_vnet[0].resource_id : try(var.network_config.failover.vnet_id, "")

  # Built-in NSG rules: allow inter-VNet traffic only; all other traffic is explicitly denied.
  # Priorities 4090–4096 are reserved. Custom rules (nsg_additional_rules) must use 100–4089.
  #
  # IMPORTANT: The DenyAllOutBound rule at priority 4096 will block Power Platform VNet injection
  # from functioning. PP VNet injection requires outbound HTTPS connectivity to Microsoft service
  # endpoints. You MUST add the required outbound allow rules via nsg_additional_rules before
  # applying this module. See the complete example for a starting point and the PP documentation:
  # https://learn.microsoft.com/en-us/power-platform/admin/vnet-support-overview
  nsg_default_rules = [
    {
      name                       = "AllowVNetInBound"
      priority                   = 4090
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
      description                = "Allow inbound traffic from within the virtual network."
    },
    {
      name                       = "DenyAllInBound"
      priority                   = 4094
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Deny all other inbound traffic."
    },
    {
      name                       = "AllowVNetOutBound"
      priority                   = 4092
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
      description                = "Allow outbound traffic to within the virtual network."
    },
    {
      name                       = "DenyAllOutBound"
      priority                   = 4096
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Deny all other outbound traffic."
    },
  ]

  # Merged NSG rules: custom rules are evaluated first (lower priority = higher precedence)
  nsg_security_rules = concat(var.nsg_additional_rules, local.nsg_default_rules)

  # NSG security rules as a map keyed by rule name, for use with the AVM NSG module
  nsg_security_rules_map = { for rule in local.nsg_security_rules : rule.name => rule }

  # Resolved PP-delegated subnet ID and name — primary
  primary_pp_subnet_id   = length(module.primary_vnet) > 0 ? module.primary_vnet[0].subnets["pp"].resource_id : try(var.network_config.primary.subnet_id, "")
  primary_pp_subnet_name = length(module.primary_vnet) > 0 ? module.primary_vnet[0].subnets["pp"].name : try(var.network_config.primary.subnet_name, "")

  # Resolved VNet ID — primary
  primary_vnet_id = length(module.primary_vnet) > 0 ? module.primary_vnet[0].resource_id : try(var.network_config.primary.vnet_id, "")

  # DNS zones keyed by zone name for for_each usage
  private_dns_zones_map = var.create_private_dns_zones ? {
    for name in var.private_dns_zone_names : name => name
  } : {}
}
