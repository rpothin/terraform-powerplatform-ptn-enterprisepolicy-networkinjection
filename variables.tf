# ==============================================================================
# Required variables (alphabetical)
# ==============================================================================

variable "enterprise_policy_location" {
  description = "The Power Platform geographic region for the enterprise policy (e.g. 'europe', 'unitedstates'). Must match the location of all linked environments."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["unitedstates", "europe", "asia", "australia", "japan", "india", "canada", "southamerica", "unitedkingdom", "france", "germany", "switzerland", "norway", "korea", "southafrica", "uae", "singapore", "sweden", "italy", "poland"], var.enterprise_policy_location)
    error_message = "enterprise_policy_location must be a valid Power Platform region (e.g. 'europe', 'unitedstates')."
  }
}

variable "enterprise_policy_name" {
  description = "The name of the enterprise policy ARM resource (Microsoft.PowerPlatform/enterprisePolicies)."
  type        = string
  nullable    = false

  validation {
    condition     = length(var.enterprise_policy_name) > 0 && length(var.enterprise_policy_name) <= 128
    error_message = "enterprise_policy_name must be between 1 and 128 characters."
  }
}

variable "environments" {
  description = <<DESCRIPTION
Map of Power Platform environments to link to the enterprise policy.
- Key: logical identifier for the environment (used as the map key in outputs).
- `id`: The Power Platform environment GUID.
All environments must be in the same Power Platform region as `enterprise_policy_location`.
Environments must be of **Managed** type — this is a prerequisite not enforced at runtime.
DESCRIPTION
  type = map(object({
    id = string
  }))
  nullable = false

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

  validation {
    condition     = length(var.environments) == length(distinct([for _, env in var.environments : lower(env.id)]))
    error_message = "Each environment must have a unique id. Duplicate environment GUIDs are not allowed."
  }
}

variable "resource_group_location" {
  description = "The Azure region for the resource group and all Azure networking resources created by this module (e.g. 'westeurope', 'eastus')."
  type        = string
  nullable    = false

  validation {
    condition     = length(var.resource_group_location) > 0
    error_message = "resource_group_location must not be empty."
  }
}

variable "resource_group_name" {
  description = "The name of the Azure resource group to create for this module's resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(var.resource_group_name) > 0 && length(var.resource_group_name) <= 90
    error_message = "resource_group_name must be between 1 and 90 characters."
  }
}

# ==============================================================================
# Optional variables (alphabetical)
# ==============================================================================

variable "create_network_infrastructure" {
  description = "When true, creates VNets, subnets (PP-delegated and private endpoint), NSGs, and VNet peering. When false, network_config must be provided with existing network details."
  type        = bool
  default     = true
  nullable    = false
}

variable "create_private_dns_zones" {
  description = "When true, creates private DNS zones listed in private_dns_zone_names and links them to the primary and failover VNets."
  type        = bool
  default     = false
  nullable    = false
}

variable "failover_vnet_config" {
  description = <<DESCRIPTION
Configuration for the failover virtual network, used when create_network_infrastructure is true.
- `location`: The Azure region for the failover VNet (e.g. "northeurope"). Required when create_network_infrastructure is true.
- `address_space`: The CIDR block for the failover VNet (default: "10.1.0.0/16").
- `pp_subnet_cidr`: CIDR for the Power Platform delegated subnet (default: "10.1.0.0/24").
- `pe_subnet_cidr`: CIDR for the private endpoint subnet (default: "10.1.1.0/24").
DESCRIPTION
  type = object({
    location       = string
    address_space  = optional(string, "10.1.0.0/16")
    pp_subnet_cidr = optional(string, "10.1.0.0/24")
    pe_subnet_cidr = optional(string, "10.1.1.0/24")
  })
  default = null
}

variable "network_config" {
  description = <<DESCRIPTION
Existing network configuration, used when create_network_infrastructure is false.
Provides VNet IDs, subnet IDs, and subnet names for primary and failover networks.
- `primary.vnet_id`: Resource ID of the existing primary VNet.
- `primary.subnet_id`: Resource ID of the existing primary PP-delegated subnet.
- `primary.subnet_name`: Name of the existing primary PP-delegated subnet.
- `failover.vnet_id`: Resource ID of the existing failover VNet.
- `failover.subnet_id`: Resource ID of the existing failover PP-delegated subnet.
- `failover.subnet_name`: Name of the existing failover PP-delegated subnet.
DESCRIPTION
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

variable "nsg_additional_rules" {
  description = <<DESCRIPTION
Additional security rules to add to the NSGs on top of the secure defaults (inter-VNet traffic only).
Priorities must be in range 100-4089 to avoid conflicts with built-in rules (priorities 4090-4096).
Each rule object supports:
- `name`: Rule name.
- `priority`: Rule priority (100-4089).
- `direction`: "Inbound" or "Outbound".
- `access`: "Allow" or "Deny".
- `protocol`: "*", "Ah", "Esp", "Icmp", "Tcp", or "Udp".
- `source_port_range`: Source port range (default: "*").
- `destination_port_range`: Destination port range (default: "*").
- `source_address_prefix`: Source address prefix (default: "*").
- `destination_address_prefix`: Destination address prefix (default: "*").
- `description`: Rule description (default: "").

Note: Power Platform VNet injection REQUIRES outbound HTTPS connectivity to Microsoft service
endpoints. The default DenyAllOutBound rule will prevent PP VNet injection from functioning
unless you add the required outbound allow rules via this variable. See the complete example
for a starting point and https://learn.microsoft.com/en-us/power-platform/admin/vnet-support-overview.
DESCRIPTION
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
    error_message = "Each NSG rule priority must be between 100 and 4089. Values 4090-4096 are reserved for built-in module rules."
  }

  validation {
    condition = alltrue([
      for rule in var.nsg_additional_rules : contains(["*", "Ah", "Esp", "Icmp", "Tcp", "Udp"], rule.protocol)
    ])
    error_message = "Each NSG rule protocol must be one of: '*', 'Ah', 'Esp', 'Icmp', 'Tcp', 'Udp'."
  }

  validation {
    condition     = length(var.nsg_additional_rules) == length(distinct([for rule in var.nsg_additional_rules : rule.name]))
    error_message = "Each NSG rule name must be unique within nsg_additional_rules."
  }

  validation {
    condition     = length(var.nsg_additional_rules) == length(distinct([for rule in var.nsg_additional_rules : rule.priority]))
    error_message = "Each NSG rule priority must be unique within nsg_additional_rules."
  }

  validation {
    condition = alltrue([
      for rule in var.nsg_additional_rules : !contains(["AllowVNetInBound", "DenyAllInBound", "AllowVNetOutBound", "DenyAllOutBound"], rule.name)
    ])
    error_message = "NSG rule names 'AllowVNetInBound', 'DenyAllInBound', 'AllowVNetOutBound', and 'DenyAllOutBound' are reserved for built-in module rules."
  }
}

variable "nsg_pe_additional_rules" {
  description = <<DESCRIPTION
Additional security rules to add to the NSGs on the private endpoint subnets, on top of the secure defaults (inter-VNet traffic only).
Priorities must be in range 100-4089 to avoid conflicts with built-in rules (priorities 4090-4096).
Each rule object supports:
- `name`: Rule name.
- `priority`: Rule priority (100-4089).
- `direction`: "Inbound" or "Outbound".
- `access`: "Allow" or "Deny".
- `protocol`: "*", "Ah", "Esp", "Icmp", "Tcp", or "Udp".
- `source_port_range`: Source port range (default: "*").
- `destination_port_range`: Destination port range (default: "*").
- `source_address_prefix`: Source address prefix (default: "*").
- `destination_address_prefix`: Destination address prefix (default: "*").
- `description`: Rule description (default: "").

Unlike the PP-delegated subnet NSG, no mandatory outbound rules are required for PE subnets — private endpoints
are passive receivers and do not initiate outbound connections. The default VNet-only rules are sufficient for
normal PE operation. Use this variable only to add extra allow/deny rules for management or monitoring traffic.
DESCRIPTION
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
      for rule in var.nsg_pe_additional_rules : contains(["Inbound", "Outbound"], rule.direction)
    ])
    error_message = "Each NSG PE rule direction must be 'Inbound' or 'Outbound'."
  }

  validation {
    condition = alltrue([
      for rule in var.nsg_pe_additional_rules : contains(["Allow", "Deny"], rule.access)
    ])
    error_message = "Each NSG PE rule access must be 'Allow' or 'Deny'."
  }

  validation {
    condition = alltrue([
      for rule in var.nsg_pe_additional_rules : rule.priority >= 100 && rule.priority <= 4089
    ])
    error_message = "Each NSG PE rule priority must be between 100 and 4089. Values 4090-4096 are reserved for built-in module rules."
  }

  validation {
    condition = alltrue([
      for rule in var.nsg_pe_additional_rules : contains(["*", "Ah", "Esp", "Icmp", "Tcp", "Udp"], rule.protocol)
    ])
    error_message = "Each NSG PE rule protocol must be one of: '*', 'Ah', 'Esp', 'Icmp', 'Tcp', 'Udp'."
  }

  validation {
    condition     = length(var.nsg_pe_additional_rules) == length(distinct([for rule in var.nsg_pe_additional_rules : rule.name]))
    error_message = "Each NSG PE rule name must be unique within nsg_pe_additional_rules."
  }

  validation {
    condition     = length(var.nsg_pe_additional_rules) == length(distinct([for rule in var.nsg_pe_additional_rules : rule.priority]))
    error_message = "Each NSG PE rule priority must be unique within nsg_pe_additional_rules."
  }

  validation {
    condition = alltrue([
      for rule in var.nsg_pe_additional_rules : !contains(["AllowVNetInBound", "DenyAllInBound", "AllowVNetOutBound", "DenyAllOutBound"], rule.name)
    ])
    error_message = "NSG PE rule names 'AllowVNetInBound', 'DenyAllInBound', 'AllowVNetOutBound', and 'DenyAllOutBound' are reserved for built-in module rules."
  }
}

variable "primary_vnet_config" {
  description = <<DESCRIPTION
Configuration for the primary virtual network, used when create_network_infrastructure is true.
- `location`: The Azure region for the primary VNet (e.g. "westeurope"). Required when create_network_infrastructure is true.
- `address_space`: The CIDR block for the primary VNet (default: "10.0.0.0/16").
- `pp_subnet_cidr`: CIDR for the Power Platform delegated subnet (default: "10.0.0.0/24").
- `pe_subnet_cidr`: CIDR for the private endpoint subnet (default: "10.0.1.0/24").
DESCRIPTION
  type = object({
    location       = string
    address_space  = optional(string, "10.0.0.0/16")
    pp_subnet_cidr = optional(string, "10.0.0.0/24")
    pe_subnet_cidr = optional(string, "10.0.1.0/24")
  })
  default = null
}

variable "private_dns_zone_names" {
  description = "List of private DNS zone names to create when create_private_dns_zones is true (e.g. ['privatelink.blob.core.windows.net'])."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for name in var.private_dns_zone_names : length(trimspace(name)) > 0])
    error_message = "Each private DNS zone name must be a non-empty string."
  }
}

variable "tags" {
  description = "A map of tags to apply to all created resources."
  type        = map(string)
  default     = {}
  nullable    = false
}

