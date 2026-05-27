variable "enterprise_policy_name" {
  description = "The name of the enterprise policy ARM resource."
  type        = string
  default     = "my-network-injection-policy"
}

variable "enterprise_policy_location" {
  description = "The Power Platform region for the enterprise policy (e.g. 'europe')."
  type        = string
  default     = "europe"
}

variable "resource_group_name" {
  description = "The name of the Azure resource group to create."
  type        = string
  default     = "rg-pp-network-injection"
}

variable "resource_group_location" {
  description = "The Azure region for the resource group and ARM enterprise policy resource."
  type        = string
  default     = "westeurope"
}

variable "environments" {
  description = "Map of Power Platform environments to link to the enterprise policy."
  type = map(object({
    id = string
  }))
  default = {
    env1 = { id = "00000000-0000-0000-0000-000000000001" }
  }
}

variable "primary_vnet_location" {
  description = "Azure region for the primary virtual network."
  type        = string
  default     = "westeurope"
}

variable "failover_vnet_location" {
  description = "Azure region for the failover virtual network."
  type        = string
  default     = "northeurope"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

