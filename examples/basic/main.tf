# Registry source: derived from the repo name — strip the "terraform-powerplatform-" prefix.
# e.g. terraform-powerplatform-res-environment → rpothin/res-environment/powerplatform
# Set this during module initialization. No version pin — always resolves to latest.
module "this" {
  source = "../../" # Replace with registry source before first release (see AGENTS.md)

  enterprise_policy_name     = var.enterprise_policy_name
  enterprise_policy_location = var.enterprise_policy_location
  resource_group_name        = var.resource_group_name
  resource_group_location    = var.resource_group_location
  environments               = var.environments

  # Network infrastructure is created by this module (default behaviour).
  # Primary and failover VNets are peered together.
  # Each VNet has a PP-delegated subnet and a private-endpoint subnet.
  primary_vnet_config = {
    location = var.primary_vnet_location
  }

  failover_vnet_config = {
    location = var.failover_vnet_location
  }

  tags = var.tags
}

