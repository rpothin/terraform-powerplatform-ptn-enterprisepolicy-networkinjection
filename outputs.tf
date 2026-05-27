output "enterprise_policy_id" {
  description = "The Azure ARM resource ID of the enterprise policy."
  value       = azapi_resource.enterprise_policy.id
}

output "enterprise_policy_system_id" {
  description = "The Power Platform system ID of the enterprise policy, used when linking environments via powerplatform_enterprise_policy."
  value       = azapi_resource.enterprise_policy.output.properties.systemId
}

output "primary_vnet_id" {
  description = "The Azure resource ID of the primary virtual network."
  value       = local.primary_vnet_id
}

output "primary_subnet_id" {
  description = "The Azure resource ID of the primary PP-delegated subnet."
  value       = local.primary_pp_subnet_id
}

output "failover_vnet_id" {
  description = "The Azure resource ID of the failover virtual network."
  value       = local.failover_vnet_id
}

output "failover_subnet_id" {
  description = "The Azure resource ID of the failover PP-delegated subnet."
  value       = local.failover_pp_subnet_id
}

output "resource_group_id" {
  description = "The Azure resource ID of the resource group."
  value       = azurerm_resource_group.this.id
}

output "resource_group_name" {
  description = "The name of the Azure resource group."
  value       = azurerm_resource_group.this.name
}

output "resource_group_location" {
  description = "The Azure region of the resource group."
  value       = azurerm_resource_group.this.location
}

