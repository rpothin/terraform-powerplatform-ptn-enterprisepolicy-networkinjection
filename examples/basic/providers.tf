terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    powerplatform = {
      source  = "microsoft/power-platform"
      version = "~> 4.0"
    }
  }
}

provider "azapi" {
  # Configuration via environment variables: ARM_TENANT_ID, ARM_CLIENT_ID
  # For OIDC: ARM_USE_OIDC=true
  use_oidc = true
}

provider "azurerm" {
  features {}
  # Configuration via environment variables: ARM_TENANT_ID, ARM_CLIENT_ID, ARM_SUBSCRIPTION_ID
  # For OIDC: ARM_USE_OIDC=true
  use_oidc = true
}

provider "powerplatform" {
  # Configuration via environment variables: POWER_PLATFORM_TENANT_ID, POWER_PLATFORM_CLIENT_ID
  # For OIDC: POWER_PLATFORM_USE_OIDC=true
  use_oidc = true
}
