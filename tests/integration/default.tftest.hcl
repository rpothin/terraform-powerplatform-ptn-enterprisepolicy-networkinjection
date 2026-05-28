# Integration tests — uses real provider, requires OIDC credentials.
#
# Prerequisites:
#   ARM_USE_OIDC=true                              (OIDC mode for azurerm + azapi providers)
#   POWER_PLATFORM_USE_OIDC=true                   (OIDC mode for the Power Platform provider)
#   POWER_PLATFORM_TENANT_ID=<your-tenant-id>
#   POWER_PLATFORM_CLIENT_ID=<your-client-id>
#   ARM_TENANT_ID=<your-tenant-id>
#   ARM_CLIENT_ID=<your-client-id>
#   ARM_SUBSCRIPTION_ID=<your-subscription-id>
#
# These tests create real resources against a Power Platform tenant and an Azure subscription.
# Resources are automatically destroyed after test completion.
#
# Required environment variables for test variable injection:
#   TF_VAR_environments — JSON map, e.g.:
#     '{"prod": {"id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"}}'

run "creates_enterprise_policy_with_managed_network" {
  command = apply

  variables {
    enterprise_policy_name     = "tftest-integration-policy"
    enterprise_policy_location = "europe"
    resource_group_name        = "rg-tftest-integration"
    resource_group_location    = "westeurope"

    primary_vnet_config = {
      location = "westeurope"
    }
    failover_vnet_config = {
      location = "northeurope"
    }

    tags = {
      environment = "integration-test"
      managed_by  = "terraform-test"
    }
    # environments provided via TF_VAR_environments
  }

  assert {
    condition     = output.enterprise_policy_id != ""
    error_message = "enterprise_policy_id output must not be empty."
  }

  assert {
    condition     = output.enterprise_policy_system_id != ""
    error_message = "enterprise_policy_system_id output must not be empty."
  }

  assert {
    condition     = output.resource_group_name == "rg-tftest-integration"
    error_message = "resource_group_name output must match the input variable."
  }

  assert {
    condition     = output.resource_group_location == "westeurope"
    error_message = "resource_group_location output must match the input variable."
  }

  assert {
    condition     = output.primary_vnet_id != ""
    error_message = "primary_vnet_id output must not be empty."
  }

  assert {
    condition     = output.failover_vnet_id != ""
    error_message = "failover_vnet_id output must not be empty."
  }

  assert {
    condition     = length(output.enterprise_policy_links) > 0
    error_message = "enterprise_policy_links output must contain at least one link."
  }
}
