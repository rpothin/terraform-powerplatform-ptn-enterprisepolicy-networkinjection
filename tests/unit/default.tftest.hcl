# Unit tests — uses mock providers, no credentials required.

mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "powerplatform" {}

# ---------------------------------------------------------------------------
# Variable validation: enterprise_policy_location
# ---------------------------------------------------------------------------

run "accepts_valid_pp_location" {
  command = plan

  variables {
    enterprise_policy_name     = "test-policy"
    enterprise_policy_location = "europe"
    resource_group_name        = "rg-test"
    resource_group_location    = "westeurope"
    environments = {
      env1 = { id = "00000000-0000-0000-0000-000000000001" }
    }
    primary_vnet_config  = { location = "westeurope" }
    failover_vnet_config = { location = "northeurope" }
  }

  assert {
    condition     = var.enterprise_policy_location == "europe"
    error_message = "enterprise_policy_location should be 'europe'."
  }
}

run "maps_uk_arm_location_alias" {
  command = plan

  variables {
    enterprise_policy_name     = "test-policy"
    enterprise_policy_location = "unitedkingdom"
    resource_group_name        = "rg-test"
    resource_group_location    = "uksouth"
    environments = {
      env1 = { id = "00000000-0000-0000-0000-000000000001" }
    }
    primary_vnet_config  = { location = "uksouth" }
    failover_vnet_config = { location = "ukwest" }
  }

  assert {
    condition     = local.enterprise_policy_arm_location == "uk"
    error_message = "enterprise_policy_arm_location should map 'unitedkingdom' to 'uk' for the ARM API."
  }
}

run "maps_southamerica_arm_location_alias" {
  command = plan

  variables {
    enterprise_policy_name     = "test-policy"
    enterprise_policy_location = "southamerica"
    resource_group_name        = "rg-test"
    resource_group_location    = "brazilsouth"
    environments = {
      env1 = { id = "00000000-0000-0000-0000-000000000001" }
    }
    primary_vnet_config  = { location = "brazilsouth" }
    failover_vnet_config = { location = "brazilsoutheast" }
  }

  assert {
    condition     = local.enterprise_policy_arm_location == "brazil"
    error_message = "enterprise_policy_arm_location should map 'southamerica' to 'brazil' for the ARM API."
  }
}

run "rejects_invalid_pp_location" {
  command = plan

  variables {
    enterprise_policy_name     = "test-policy"
    enterprise_policy_location = "invalidregion"
    resource_group_name        = "rg-test"
    resource_group_location    = "westeurope"
    environments = {
      env1 = { id = "00000000-0000-0000-0000-000000000001" }
    }
    primary_vnet_config  = { location = "westeurope" }
    failover_vnet_config = { location = "northeurope" }
  }

  expect_failures = [
    var.enterprise_policy_location,
  ]
}

# ---------------------------------------------------------------------------
# Variable validation: environments map
# ---------------------------------------------------------------------------

run "rejects_empty_environments" {
  command = plan

  variables {
    enterprise_policy_name     = "test-policy"
    enterprise_policy_location = "europe"
    resource_group_name        = "rg-test"
    resource_group_location    = "westeurope"
    environments               = {}
    primary_vnet_config        = { location = "westeurope" }
    failover_vnet_config       = { location = "northeurope" }
  }

  expect_failures = [
    var.environments,
  ]
}

run "rejects_invalid_environment_guid" {
  command = plan

  variables {
    enterprise_policy_name     = "test-policy"
    enterprise_policy_location = "europe"
    resource_group_name        = "rg-test"
    resource_group_location    = "westeurope"
    environments = {
      env1 = { id = "not-a-guid" }
    }
    primary_vnet_config  = { location = "westeurope" }
    failover_vnet_config = { location = "northeurope" }
  }

  expect_failures = [
    var.environments,
  ]
}

# ---------------------------------------------------------------------------
# Variable validation: NSG additional rules
# ---------------------------------------------------------------------------

run "rejects_nsg_rule_with_invalid_direction" {
  command = plan

  variables {
    enterprise_policy_name     = "test-policy"
    enterprise_policy_location = "europe"
    resource_group_name        = "rg-test"
    resource_group_location    = "westeurope"
    environments = {
      env1 = { id = "00000000-0000-0000-0000-000000000001" }
    }
    primary_vnet_config  = { location = "westeurope" }
    failover_vnet_config = { location = "northeurope" }
    nsg_additional_rules = [
      {
        name      = "bad-rule"
        priority  = 200
        direction = "Both" # invalid
        access    = "Allow"
        protocol  = "Tcp"
      }
    ]
  }

  expect_failures = [
    var.nsg_additional_rules,
  ]
}

run "rejects_nsg_rule_with_priority_out_of_range" {
  command = plan

  variables {
    enterprise_policy_name     = "test-policy"
    enterprise_policy_location = "europe"
    resource_group_name        = "rg-test"
    resource_group_location    = "westeurope"
    environments = {
      env1 = { id = "00000000-0000-0000-0000-000000000001" }
    }
    primary_vnet_config  = { location = "westeurope" }
    failover_vnet_config = { location = "northeurope" }
    nsg_additional_rules = [
      {
        name      = "high-priority-rule"
        priority  = 4095 # reserved range: 4090–4096
        direction = "Inbound"
        access    = "Allow"
        protocol  = "*"
      }
    ]
  }

  expect_failures = [
    var.nsg_additional_rules,
  ]
}

# ---------------------------------------------------------------------------
# create_network_infrastructure = true (default): outputs resolved from created resources
# ---------------------------------------------------------------------------

run "creates_network_infrastructure_by_default" {
  command = plan

  variables {
    enterprise_policy_name     = "test-policy"
    enterprise_policy_location = "europe"
    resource_group_name        = "rg-test"
    resource_group_location    = "westeurope"
    environments = {
      env1 = { id = "00000000-0000-0000-0000-000000000001" }
    }
    primary_vnet_config  = { location = "westeurope" }
    failover_vnet_config = { location = "northeurope" }
  }

  assert {
    condition     = var.create_network_infrastructure == true
    error_message = "create_network_infrastructure should default to true."
  }
}

# ---------------------------------------------------------------------------
# create_network_infrastructure = false: uses provided network_config
# ---------------------------------------------------------------------------

run "uses_provided_network_config_when_not_creating_infra" {
  command = plan

  variables {
    enterprise_policy_name        = "test-policy"
    enterprise_policy_location    = "europe"
    resource_group_name           = "rg-test"
    resource_group_location       = "westeurope"
    create_network_infrastructure = false
    environments = {
      env1 = { id = "00000000-0000-0000-0000-000000000001" }
    }
    network_config = {
      primary = {
        vnet_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-primary"
        subnet_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-primary/subnets/pp-subnet"
        subnet_name = "pp-subnet"
      }
      failover = {
        vnet_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-failover"
        subnet_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-failover/subnets/pp-subnet"
        subnet_name = "pp-subnet"
      }
    }
  }

  assert {
    condition     = var.create_network_infrastructure == false
    error_message = "create_network_infrastructure should be false."
  }

  assert {
    condition     = output.primary_vnet_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-primary"
    error_message = "primary_vnet_id should come from network_config when create_network_infrastructure is false."
  }
}

# ---------------------------------------------------------------------------
# Tags variable
# ---------------------------------------------------------------------------

run "accepts_tags" {
  command = plan

  variables {
    enterprise_policy_name     = "test-policy"
    enterprise_policy_location = "europe"
    resource_group_name        = "rg-test"
    resource_group_location    = "westeurope"
    environments = {
      env1 = { id = "00000000-0000-0000-0000-000000000001" }
    }
    primary_vnet_config  = { location = "westeurope" }
    failover_vnet_config = { location = "northeurope" }
    tags = {
      environment = "test"
      managed_by  = "terraform"
    }
  }

  assert {
    condition     = var.tags["environment"] == "test"
    error_message = "Tags should be accepted."
  }
}

# ---------------------------------------------------------------------------
# Private DNS zones flag
# ---------------------------------------------------------------------------

run "create_private_dns_zones_defaults_to_false" {
  command = plan

  variables {
    enterprise_policy_name     = "test-policy"
    enterprise_policy_location = "europe"
    resource_group_name        = "rg-test"
    resource_group_location    = "westeurope"
    environments = {
      env1 = { id = "00000000-0000-0000-0000-000000000001" }
    }
    primary_vnet_config  = { location = "westeurope" }
    failover_vnet_config = { location = "northeurope" }
  }

  assert {
    condition     = var.create_private_dns_zones == false
    error_message = "create_private_dns_zones should default to false."
  }
}


