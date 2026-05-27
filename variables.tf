variable "enterprise_policy_name" {
  description = "The name of the enterprise policy ARM resource (Microsoft.PowerPlatform/enterprisePolicies)."
  type        = string

  validation {
    condition     = length(var.enterprise_policy_name) > 0 && length(var.enterprise_policy_name) <= 128
    error_message = "enterprise_policy_name must be between 1 and 128 characters."
  }
}

variable "enterprise_policy_location" {
  description = "The Power Platform geographic region for the enterprise policy (e.g. 'europe', 'unitedstates'). Must match the location of all linked environments."
  type        = string

  validation {
    condition     = contains(["unitedstates", "europe", "asia", "australia", "japan", "india", "canada", "southamerica", "unitedkingdom", "france", "germany", "switzerland", "norway", "korea", "southafrica", "uae", "singapore"], var.enterprise_policy_location)
    error_message = "enterprise_policy_location must be a valid Power Platform region (e.g. 'europe', 'unitedstates')."
  }
}

variable "resource_group_name" {
  description = "The name of the Azure resource group to create for this module's resources."
  type        = string

  validation {
    condition     = length(var.resource_group_name) > 0 && length(var.resource_group_name) <= 90
    error_message = "resource_group_name must be between 1 and 90 characters."
  }
}

variable "resource_group_location" {
  description = "The Azure region for the resource group and ARM enterprise policy resource (e.g. 'westeurope', 'eastus')."
  type        = string

  validation {
    condition     = length(var.resource_group_location) > 0
    error_message = "resource_group_location must not be empty."
  }
}

variable "environments" {
  description = "Map of Power Platform environments to link to the enterprise policy. Key is a logical identifier; value contains the environment GUID. All environments must be in the same Power Platform region as enterprise_policy_location. Environments must be of Managed type (prerequisite — not enforced at runtime)."
  type = map(object({
    id = string
  }))

  validation {
    condition     = length(var.environments) > 0
    error_message = "At least one environment must be specified in environments."
  }

  validation {
    condition = alltrue([
      for key, env in var.environments :
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", env.id))
    ])
    error_message = "Each environment id must be a valid GUID (format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}

variable "create_network_infrastructure" {
  description = "When true, creates VNets, subnets (PP-delegated and private endpoint), NSGs, and VNet peering. When false, network_config must be provided with existing network details."
  type        = bool
  default     = true
  nullable    = false
}

variable "primary_vnet_config" {
  description = "Configuration for the primary virtual network. Required when create_network_infrastructure is true. CIDR ranges default to non-overlapping values (10.0.0.0/16, 10.0.0.0/24, 10.0.1.0/24)."
  type = object({
    location       = string
    address_space  = optional(string, "10.0.0.0/16")
    pp_subnet_cidr = optional(string, "10.0.0.0/24")
    pe_subnet_cidr = optional(string, "10.0.1.0/24")
  })
  default = null
}

variable "failover_vnet_config" {
  description = "Configuration for the failover virtual network. Required when create_network_infrastructure is true. CIDR ranges default to non-overlapping values (10.1.0.0/16, 10.1.0.0/24, 10.1.1.0/24)."
  type = object({
    location       = string
    address_space  = optional(string, "10.1.0.0/16")
    pp_subnet_cidr = optional(string, "10.1.0.0/24")
    pe_subnet_cidr = optional(string, "10.1.1.0/24")
  })
  default = null
}

variable "nsg_additional_rules" {
  description = "Additional security rules to add to the NSGs on top of the secure defaults (inter-VNet traffic only). Priorities must be in range 100–4089 to avoid conflicts with built-in rules. Note: Power Platform VNet injection may require outbound rules for Microsoft service endpoints — add them here if needed."
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = optional(string, "*")
    destination_port_range     = optional(string, "*")
    source_address_prefix      = optional(string, "*")
    destination_address_prefix = optional(string, "*")
    description                = optional(string, "")
  }))
  default  = []
  nullable = false

  validation {
    condition = alltrue([
      for rule in var.nsg_additional_rules : contains(["Inbound", "Outbound"], rule.direction)
    ])
    error_message = "Each NSG rule direction must be 'Inbound' or 'Outbound'."
  }

  validation {
    condition = alltrue([
      for rule in var.nsg_additional_rules : contains(["Allow", "Deny"], rule.access)
    ])
    error_message = "Each NSG rule access must be 'Allow' or 'Deny'."
  }

  validation {
    condition = alltrue([
      for rule in var.nsg_additional_rules : rule.priority >= 100 && rule.priority <= 4089
    ])
    error_message = "Each NSG rule priority must be between 100 and 4089. Values 4090–4096 are reserved for built-in module rules."
  }
}

variable "network_config" {
  description = "Existing network configuration to use when create_network_infrastructure is false. Provides VNet IDs, subnet IDs, and subnet names for primary and failover networks."
  type = object({
    primary = object({
      vnet_id     = string
      subnet_id   = string
      subnet_name = string
    })
    failover = object({
      vnet_id     = string
      subnet_id   = string
      subnet_name = string
    })
  })
  default = null
}

variable "create_private_dns_zones" {
  description = "When true, creates private DNS zones listed in private_dns_zone_names and links them to the primary and failover VNets."
  type        = bool
  default     = false
  nullable    = false
}

variable "private_dns_zone_names" {
  description = "List of private DNS zone names to create when create_private_dns_zones is true (e.g. ['privatelink.blob.core.windows.net'])."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "tags" {
  description = "A map of tags to apply to all created resources."
  type        = map(string)
  default     = {}
  nullable    = false
}

