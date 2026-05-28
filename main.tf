data "powerplatform_environments" "all" {}

# ==============================================================================
# RESOURCE GROUP
# ==============================================================================

resource "azurerm_resource_group" "this" {
  location = var.resource_group_location
  name     = var.resource_group_name
  tags     = var.tags
}

# ==============================================================================
# NETWORK INFRASTRUCTURE (conditional on create_network_infrastructure)
# ==============================================================================

resource "azurerm_virtual_network" "primary" {
  count = var.create_network_infrastructure ? 1 : 0

  address_space       = [var.primary_vnet_config.address_space]
  location            = var.primary_vnet_config.location
  name                = "${var.enterprise_policy_name}-primary-vnet"
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_subnet" "primary_pp" {
  count = var.create_network_infrastructure ? 1 : 0

  address_prefixes     = [var.primary_vnet_config.pp_subnet_cidr]
  name                 = "${var.enterprise_policy_name}-primary-pp-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.primary[0].name

  delegation {
    name = "power-platform-delegation"

    service_delegation {
      name = "Microsoft.PowerPlatform/enterprisePolicies"
    }
  }
}

resource "azurerm_subnet" "primary_pe" {
  count = var.create_network_infrastructure ? 1 : 0

  address_prefixes     = [var.primary_vnet_config.pe_subnet_cidr]
  name                 = "${var.enterprise_policy_name}-primary-pe-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.primary[0].name
}

resource "azurerm_network_security_group" "primary" {
  count = var.create_network_infrastructure ? 1 : 0

  location            = var.primary_vnet_config.location
  name                = "${var.enterprise_policy_name}-primary-nsg"
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  dynamic "security_rule" {
    for_each = local.nsg_security_rules

    content {
      access                     = security_rule.value.access
      description                = security_rule.value.description
      destination_address_prefix = security_rule.value.destination_address_prefix
      destination_port_range     = security_rule.value.destination_port_range
      direction                  = security_rule.value.direction
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      protocol                   = security_rule.value.protocol
      source_address_prefix      = security_rule.value.source_address_prefix
      source_port_range          = security_rule.value.source_port_range
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "primary_pp" {
  count = var.create_network_infrastructure ? 1 : 0

  network_security_group_id = azurerm_network_security_group.primary[0].id
  subnet_id                 = azurerm_subnet.primary_pp[0].id
}

resource "azurerm_virtual_network" "failover" {
  count = var.create_network_infrastructure ? 1 : 0

  address_space       = [var.failover_vnet_config.address_space]
  location            = var.failover_vnet_config.location
  name                = "${var.enterprise_policy_name}-failover-vnet"
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_subnet" "failover_pp" {
  count = var.create_network_infrastructure ? 1 : 0

  address_prefixes     = [var.failover_vnet_config.pp_subnet_cidr]
  name                 = "${var.enterprise_policy_name}-failover-pp-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.failover[0].name

  delegation {
    name = "power-platform-delegation"

    service_delegation {
      name = "Microsoft.PowerPlatform/enterprisePolicies"
    }
  }
}

resource "azurerm_subnet" "failover_pe" {
  count = var.create_network_infrastructure ? 1 : 0

  address_prefixes     = [var.failover_vnet_config.pe_subnet_cidr]
  name                 = "${var.enterprise_policy_name}-failover-pe-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.failover[0].name
}

resource "azurerm_network_security_group" "failover" {
  count = var.create_network_infrastructure ? 1 : 0

  location            = var.failover_vnet_config.location
  name                = "${var.enterprise_policy_name}-failover-nsg"
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  dynamic "security_rule" {
    for_each = local.nsg_security_rules

    content {
      access                     = security_rule.value.access
      description                = security_rule.value.description
      destination_address_prefix = security_rule.value.destination_address_prefix
      destination_port_range     = security_rule.value.destination_port_range
      direction                  = security_rule.value.direction
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      protocol                   = security_rule.value.protocol
      source_address_prefix      = security_rule.value.source_address_prefix
      source_port_range          = security_rule.value.source_port_range
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "failover_pp" {
  count = var.create_network_infrastructure ? 1 : 0

  network_security_group_id = azurerm_network_security_group.failover[0].id
  subnet_id                 = azurerm_subnet.failover_pp[0].id
}

resource "azurerm_virtual_network_peering" "primary_to_failover" {
  count = var.create_network_infrastructure ? 1 : 0

  name                      = "${var.enterprise_policy_name}-primary-to-failover"
  remote_virtual_network_id = azurerm_virtual_network.failover[0].id
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = azurerm_virtual_network.primary[0].name
}

resource "azurerm_virtual_network_peering" "failover_to_primary" {
  count = var.create_network_infrastructure ? 1 : 0

  name                      = "${var.enterprise_policy_name}-failover-to-primary"
  remote_virtual_network_id = azurerm_virtual_network.primary[0].id
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = azurerm_virtual_network.failover[0].name
}

# ==============================================================================
# PRIVATE DNS ZONES (conditional on create_private_dns_zones)
# ==============================================================================

resource "azurerm_private_dns_zone" "this" {
  for_each = local.private_dns_zones_map

  name                = each.key
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "primary" {
  for_each = local.private_dns_zones_map

  name                  = "${replace(each.key, ".", "-")}-primary-link"
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  resource_group_name   = azurerm_resource_group.this.name
  tags                  = var.tags
  virtual_network_id    = local.primary_vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "failover" {
  for_each = local.private_dns_zones_map

  name                  = "${replace(each.key, ".", "-")}-failover-link"
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  resource_group_name   = azurerm_resource_group.this.name
  tags                  = var.tags
  virtual_network_id    = local.failover_vnet_id
}

# ==============================================================================
# ENTERPRISE POLICY ARM RESOURCE
# ==============================================================================

resource "azapi_resource" "enterprise_policy" {
  # Required arguments (alphabetical)
  body      = local.enterprise_policy_body
  location  = local.enterprise_policy_arm_location
  name      = var.enterprise_policy_name
  parent_id = azurerm_resource_group.this.id
  type      = "Microsoft.PowerPlatform/enterprisePolicies@2020-10-30-preview"

  # Optional arguments and blocks (alphabetical)
  identity {
    type = "SystemAssigned"
  }

  response_export_values = ["properties.systemId", "properties.healthStatus"]
  tags                   = var.tags

  timeouts {
    create = "30m"
    delete = "20m"
    read   = "5m"
    update = "30m"
  }

  # Meta-arguments (depends_on before lifecycle per TFNFR8)
  depends_on = [
    azurerm_subnet_network_security_group_association.primary_pp,
    azurerm_subnet_network_security_group_association.failover_pp,
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
