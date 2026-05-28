output "enterprise_policy_id" {
  description = "The Azure ARM resource ID of the enterprise policy."
  value       = module.this.enterprise_policy_id
}

output "enterprise_policy_system_id" {
  description = "The Power Platform system ID of the enterprise policy."
  value       = module.this.enterprise_policy_system_id
}

output "primary_vnet_id" {
  description = "The Azure resource ID of the primary virtual network."
  value       = module.this.primary_vnet_id
}

output "primary_subnet_id" {
  description = "The Azure resource ID of the primary PP-delegated subnet."
  value       = module.this.primary_subnet_id
}

output "failover_vnet_id" {
  description = "The Azure resource ID of the failover virtual network."
  value       = module.this.failover_vnet_id
}

output "failover_subnet_id" {
  description = "The Azure resource ID of the failover PP-delegated subnet."
  value       = module.this.failover_subnet_id
}

output "resource_group_id" {
  description = "The Azure resource ID of the resource group."
  value       = module.this.resource_group_id
}

output "resource_group_name" {
  description = "The name of the Azure resource group."
  value       = module.this.resource_group_name
}

