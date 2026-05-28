data "powerplatform_environments" "all" {}

# ==============================================================================
# INPUT VALIDATION (cross-variable preconditions)
# ==============================================================================

resource "terraform_data" "preconditions" {
  lifecycle {
    precondition {
      condition     = !var.create_network_infrastructure || (var.primary_vnet_config != null && var.failover_vnet_config != null)
      error_message = "primary_vnet_config and failover_vnet_config must be provided when create_network_infrastructure is true."
    }

    precondition {
      condition     = var.create_network_infrastructure || var.network_config != null
      error_message = "network_config must be provided when create_network_infrastructure is false."
    }

    precondition {
      condition     = !var.create_network_infrastructure || var.primary_vnet_config == null || var.failover_vnet_config == null || var.primary_vnet_config.location != var.failover_vnet_config.location
      error_message = "primary_vnet_config.location and failover_vnet_config.location must be in different Azure regions for true failover resiliency."
    }
  }
}

# ==============================================================================
# RESOURCE GROUP
# ==============================================================================

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.4"

  enable_telemetry = false
  location         = var.resource_group_location
  name             = var.resource_group_name
  tags             = var.tags
}

# ==============================================================================
# NETWORK INFRASTRUCTURE (conditional on create_network_infrastructure)
# ==============================================================================

module "primary_nsg" {
  count   = var.create_network_infrastructure && var.primary_vnet_config != null && var.failover_vnet_config != null ? 1 : 0
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "~> 0.5"

  enable_telemetry    = false
  location            = try(var.primary_vnet_config.location, "")
  name                = "${var.enterprise_policy_name}-primary-nsg"
  resource_group_name = module.resource_group.name
  security_rules      = local.nsg_security_rules_map
  tags                = var.tags
}

module "failover_nsg" {
  count   = var.create_network_infrastructure && var.primary_vnet_config != null && var.failover_vnet_config != null ? 1 : 0
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "~> 0.5"

  enable_telemetry    = false
  location            = try(var.failover_vnet_config.location, "")
  name                = "${var.enterprise_policy_name}-failover-nsg"
  resource_group_name = module.resource_group.name
  security_rules      = local.nsg_security_rules_map
  tags                = var.tags
}

module "primary_pe_nsg" {
  count   = var.create_network_infrastructure && var.primary_vnet_config != null && var.failover_vnet_config != null ? 1 : 0
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "~> 0.5"

  enable_telemetry    = false
  location            = try(var.primary_vnet_config.location, "")
  name                = "${var.enterprise_policy_name}-primary-pe-nsg"
  resource_group_name = module.resource_group.name
  security_rules      = local.nsg_pe_security_rules_map
  tags                = var.tags
}

module "failover_pe_nsg" {
  count   = var.create_network_infrastructure && var.primary_vnet_config != null && var.failover_vnet_config != null ? 1 : 0
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "~> 0.5"

  enable_telemetry    = false
  location            = try(var.failover_vnet_config.location, "")
  name                = "${var.enterprise_policy_name}-failover-pe-nsg"
  resource_group_name = module.resource_group.name
  security_rules      = local.nsg_pe_security_rules_map
  tags                = var.tags
}

module "primary_vnet" {
  count   = var.create_network_infrastructure && var.primary_vnet_config != null && var.failover_vnet_config != null ? 1 : 0
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.17"

  address_space    = [try(var.primary_vnet_config.address_space, "10.0.0.0/16")]
  enable_telemetry = false
  location         = try(var.primary_vnet_config.location, "")
  name             = "${var.enterprise_policy_name}-primary-vnet"
  parent_id        = module.resource_group.resource_id
  tags             = var.tags

  subnets = {
    pp = {
      name             = "${var.enterprise_policy_name}-primary-pp-subnet"
      address_prefixes = [try(var.primary_vnet_config.pp_subnet_cidr, "10.0.0.0/24")]
      delegations = [{
        name = "power-platform-delegation"
        service_delegation = {
          name = "Microsoft.PowerPlatform/enterprisePolicies"
        }
      }]
      network_security_group = {
        id = module.primary_nsg[0].resource_id
      }
    }
    pe = {
      name                              = "${var.enterprise_policy_name}-primary-pe-subnet"
      address_prefixes                  = [try(var.primary_vnet_config.pe_subnet_cidr, "10.0.1.0/24")]
      private_endpoint_network_policies = "NetworkSecurityGroupEnabled"
      network_security_group = {
        id = module.primary_pe_nsg[0].resource_id
      }
    }
  }
}

module "failover_vnet" {
  count   = var.create_network_infrastructure && var.primary_vnet_config != null && var.failover_vnet_config != null ? 1 : 0
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.17"

  address_space    = [try(var.failover_vnet_config.address_space, "10.1.0.0/16")]
  enable_telemetry = false
  location         = try(var.failover_vnet_config.location, "")
  name             = "${var.enterprise_policy_name}-failover-vnet"
  parent_id        = module.resource_group.resource_id
  tags             = var.tags

  # Peerings defined on failover to avoid circular dependency: primary has no
  # peer dependencies. create_reverse_peering = true automatically creates the
  # reciprocal primary→failover peering within this module call.
  # allow_forwarded_traffic = true on both directions enables cross-region PE
  # access: a PE in one region's subnet can be reached from the other region.
  peerings = {
    to_primary = {
      name                               = "${var.enterprise_policy_name}-failover-to-primary"
      remote_virtual_network_resource_id = module.primary_vnet[0].resource_id
      create_reverse_peering             = true
      reverse_name                       = "${var.enterprise_policy_name}-primary-to-failover"
      allow_forwarded_traffic            = true
      reverse_allow_forwarded_traffic    = true
    }
  }

  subnets = {
    pp = {
      name             = "${var.enterprise_policy_name}-failover-pp-subnet"
      address_prefixes = [try(var.failover_vnet_config.pp_subnet_cidr, "10.1.0.0/24")]
      delegations = [{
        name = "power-platform-delegation"
        service_delegation = {
          name = "Microsoft.PowerPlatform/enterprisePolicies"
        }
      }]
      network_security_group = {
        id = module.failover_nsg[0].resource_id
      }
    }
    pe = {
      name                              = "${var.enterprise_policy_name}-failover-pe-subnet"
      address_prefixes                  = [try(var.failover_vnet_config.pe_subnet_cidr, "10.1.1.0/24")]
      private_endpoint_network_policies = "NetworkSecurityGroupEnabled"
      network_security_group = {
        id = module.failover_pe_nsg[0].resource_id
      }
    }
  }
}

# ==============================================================================
# PRIVATE DNS ZONES (conditional on create_private_dns_zones)
# ==============================================================================

module "private_dns_zone" {
  for_each = local.private_dns_zones_map
  source   = "Azure/avm-res-network-privatednszone/azurerm"
  version  = "~> 0.5"

  domain_name      = each.key
  enable_telemetry = false
  parent_id        = module.resource_group.resource_id
  tags             = var.tags

  virtual_network_links = {
    primary = {
      name               = "${replace(each.key, ".", "-")}-primary-link"
      virtual_network_id = local.primary_vnet_id
    }
    failover = {
      name               = "${replace(each.key, ".", "-")}-failover-link"
      virtual_network_id = local.failover_vnet_id
    }
  }
}

# ==============================================================================
# ENTERPRISE POLICY ARM RESOURCE
# ==============================================================================

resource "azapi_resource" "enterprise_policy" {
  # Required arguments (alphabetical)
  body      = local.enterprise_policy_body
  location  = local.enterprise_policy_arm_location
  name      = var.enterprise_policy_name
  parent_id = module.resource_group.resource_id
  type      = "Microsoft.PowerPlatform/enterprisePolicies@2020-10-30-preview"

  # Optional arguments (alphabetical, before optional nested blocks per TFNFR8)
  response_export_values = ["properties.systemId", "properties.healthStatus"]
  tags                   = var.tags

  # Optional nested blocks (alphabetical)
  identity {
    type = "SystemAssigned"
  }

  timeouts {
    create = "30m"
    delete = "20m"
    read   = "5m"
    update = "30m"
  }

  # Meta-arguments (depends_on before lifecycle per TFNFR8)
  depends_on = [
    terraform_data.preconditions,
    module.primary_vnet,
    module.failover_vnet,
  ]

  lifecycle {
    ignore_changes = [
      body.properties.healthStatus,
      body.properties.systemId,
      body.properties.createdTime,
      body.properties.lastModifiedTime,
    ]
  }
}

# ==============================================================================
# ENTERPRISE POLICY LINKS (Power Platform environments)
# ==============================================================================

resource "powerplatform_enterprise_policy" "this" {
  for_each = var.environments

  environment_id = each.value.id
  policy_type    = "NetworkInjection"
  system_id      = azapi_resource.enterprise_policy.output.properties.systemId

  lifecycle {
    # Guard with length check so that the preconditions are skipped when the
    # data source returns no data (e.g., during unit tests with mock providers).
    precondition {
      condition     = length(data.powerplatform_environments.all.environments) == 0 || contains(keys(local.environments_by_id), each.value.id)
      error_message = "Environment '${each.key}' (ID: ${each.value.id}) was not found in the tenant. Verify the environment ID is correct and the provider has access to it."
    }

    precondition {
      condition     = length(data.powerplatform_environments.all.environments) == 0 || !contains(keys(local.environments_by_id), each.value.id) || local.environments_by_id[each.value.id].location == var.enterprise_policy_location
      error_message = "Environment '${each.key}' is not in the '${var.enterprise_policy_location}' Power Platform region. All environments must match enterprise_policy_location."
    }
  }
}

