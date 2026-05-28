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

## Writing Tests

See the [Terraform Testing Guide](../.agents/skills/terraform-testing/SKILL.md) for detailed guidance on writing tests, including mock provider patterns and assertion examples.
