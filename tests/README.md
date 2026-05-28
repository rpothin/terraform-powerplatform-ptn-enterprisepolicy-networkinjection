# Tests

This directory contains Terraform native tests (`.tftest.hcl`) for the module.

## Prerequisites

- **Terraform >= 1.9** (mock providers require >= 1.7)
- **OIDC credentials** for integration tests (optional)

## Test Organization

| Directory | Type | Credentials | Command |
|-----------|------|-------------|---------|
| `unit/` | Mock provider tests | None required | `command = plan` |
| `integration/` | Real provider tests | OIDC required | `command = apply` |

## Running Tests

### Unit Tests

Unit tests use mock providers and require no credentials:

```bash
terraform init -backend=false
terraform test -test-directory=tests/unit
```

### Integration Tests

Integration tests create real resources and require OIDC authentication:

```bash
# Azure providers (azurerm + azapi)
export ARM_USE_OIDC=true
export ARM_TENANT_ID=<your-tenant-id>
export ARM_CLIENT_ID=<your-client-id>
export ARM_SUBSCRIPTION_ID=<your-subscription-id>

# Power Platform provider
export POWER_PLATFORM_USE_OIDC=true
export POWER_PLATFORM_TENANT_ID=<your-tenant-id>
export POWER_PLATFORM_CLIENT_ID=<your-client-id>

# Required module variable (JSON map of managed PP environments to link)
export TF_VAR_environments='{"prod": {"id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"}}'

# Location variables (must match your tenant's PP region and corresponding Azure regions)
export TF_VAR_enterprise_policy_location="unitedstates"
export TF_VAR_resource_group_location="eastus2"
export TF_VAR_primary_vnet_config='{"location":"eastus2"}'
export TF_VAR_failover_vnet_config='{"location":"westus2"}'

terraform init -backend=false
terraform test -test-directory=tests/integration
```

### All Tests

```bash
terraform test
```

### Verbose Output

```bash
terraform test -verbose
```

## CI Configuration

Integration tests run automatically in CI when `ENABLE_INTEGRATION_TESTS` is set to `true`. They require:

### Repository Secrets

| Secret | Description |
|--------|-------------|
| `POWER_PLATFORM_TENANT_ID` | Azure AD tenant ID |
| `POWER_PLATFORM_CLIENT_ID` | Service principal client ID (PP OIDC) |
| `ARM_TENANT_ID` | Azure AD tenant ID |
| `ARM_CLIENT_ID` | Service principal client ID (ARM OIDC) |
| `ARM_SUBSCRIPTION_ID` | Target Azure subscription ID |
| `TF_VAR_ENVIRONMENTS` | JSON map of environments, e.g. `{"prod":{"id":"..."}}` |

### Repository Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `ENABLE_INTEGRATION_TESTS` | Set to `true` to enable the integration test job | `true` |
| `TF_VAR_ENTERPRISE_POLICY_LOCATION` | PP region matching linked environments | `unitedstates` |
| `TF_VAR_RESOURCE_GROUP_LOCATION` | Azure region for the resource group | `eastus2` |
| `TF_VAR_PRIMARY_VNET_CONFIG` | JSON VNet config for the primary region | `{"location":"eastus2"}` |
| `TF_VAR_FAILOVER_VNET_CONFIG` | JSON VNet config for the failover region | `{"location":"westus2"}` |

> **Note:** `TF_VAR_ENTERPRISE_POLICY_LOCATION` must match the `location` field of all environments listed in `TF_VAR_ENVIRONMENTS`. Use the Power Platform admin center to confirm your environment's region before configuring these values.

## Writing Tests

See the [Terraform Testing Guide](../.agents/skills/terraform-testing/SKILL.md) for detailed guidance on writing tests, including mock provider patterns and assertion examples.
