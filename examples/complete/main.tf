# Registry source: derived from the repo name — strip the "terraform-powerplatform-" prefix.
# e.g. terraform-powerplatform-res-environment → rpothin/res-environment/powerplatform
# Set this during module initialization. No version pin — always resolves to latest.
module "this" {
  source = "rpothin/ptn-enterprisepolicy-networkinjection/powerplatform"

  enterprise_policy_name     = var.enterprise_policy_name
  enterprise_policy_location = var.enterprise_policy_location
  resource_group_name        = var.resource_group_name
  resource_group_location    = var.resource_group_location
  environments               = var.environments

  # Network infrastructure with custom CIDR configuration
  primary_vnet_config = {
    location       = var.primary_vnet_location
    address_space  = "10.10.0.0/16"
    pp_subnet_cidr = "10.10.0.0/24"
    pe_subnet_cidr = "10.10.1.0/24"
  }

  failover_vnet_config = {
    location       = var.failover_vnet_location
    address_space  = "10.11.0.0/16"
    pp_subnet_cidr = "10.11.0.0/24"
    pe_subnet_cidr = "10.11.1.0/24"
  }

  # Additional NSG rules on top of the secure defaults.
  # Example: allow outbound HTTPS to Microsoft service endpoints required by Power Platform.
  nsg_additional_rules = [
    {
      name                       = "AllowOutboundHttpsToInternet"
      priority                   = 200
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "Internet"
      description                = "Allow outbound HTTPS to Microsoft service endpoints required by Power Platform."
    },
  ]

  # Create private DNS zones and link them to both VNets
  create_private_dns_zones = true
  private_dns_zone_names   = var.private_dns_zone_names

  tags = var.tags
}

