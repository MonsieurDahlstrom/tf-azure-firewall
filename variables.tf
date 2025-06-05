# Resource Group variables
variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The Azure region where resources will be created"
}

# Hub Virtual Network Configuration
variable "hub_vnet_config" {
  type = object({
    vnet_name              = optional(string, "hub-vnet")
    address_space          = optional(list(string), ["10.0.0.0/16"])
    firewall_subnet_cidr   = optional(string, "10.0.1.0/26")
    management_subnet_cidr = optional(string, "10.0.2.0/26")  # For forced tunneling
    create_vnet           = optional(bool, true)
  })
  default = {
    vnet_name              = "hub-vnet"
    address_space          = ["10.0.0.0/16"]
    firewall_subnet_cidr   = "10.0.1.0/26"
    management_subnet_cidr = "10.0.2.0/26"
    create_vnet           = true
  }
  description = "Configuration for Hub Virtual Network"
}

# Existing Hub VNet (for when create_vnet = false)
variable "existing_hub_vnet_id" {
  type        = string
  default     = null
  description = "ID of existing hub virtual network (used when hub_vnet_config.create_vnet = false)"
}

variable "existing_firewall_subnet_id" {
  type        = string
  default     = null
  description = "ID of existing AzureFirewallSubnet (used when hub_vnet_config.create_vnet = false)"
}

variable "existing_management_subnet_id" {
  type        = string
  default     = null
  description = "ID of existing AzureFirewallManagementSubnet (used when hub_vnet_config.create_vnet = false)"
}

# Firewall configuration variables
variable "firewall_config" {
  type = object({
    name              = optional(string, "azure-firewall")
    sku_tier          = optional(string, "Standard")
    threat_intel_mode = optional(string, "Deny")
    public_ip_count   = optional(number, 1)
    public_ip_names   = optional(list(string), [])
    zones             = optional(list(string), [])
    forced_tunneling  = optional(bool, false)
    dns_servers       = optional(list(string), [])
    private_ip_ranges = optional(list(string), [])
    idps_signature_overrides = optional(list(object({
      id    = string
      state = string
    })), [])
    idps_traffic_bypass = optional(list(object({
      name                  = string
      protocol              = string
      description           = optional(string)
      destination_addresses = optional(list(string))
      destination_ip_groups = optional(list(string))
      destination_ports     = optional(list(string))
      source_addresses      = optional(list(string))
      source_ip_groups      = optional(list(string))
    })), [])
  })
  default = {
    name              = "azure-firewall"
    sku_tier          = "Standard"
    threat_intel_mode = "Deny"
    public_ip_count   = 1
    public_ip_names   = []
    zones             = []
    forced_tunneling  = false
    dns_servers       = []
    private_ip_ranges = []
    idps_signature_overrides = []
    idps_traffic_bypass = []
  }
  description = "Configuration for Azure Firewall. Note: IDPS features require Premium SKU tier for security compliance."
}

# Analytics variables
variable "firewall_analytics_retention_days" {
  type        = number
  default     = 30
  description = "The number of days to retain logs in the Log Analytics workspace"
}

variable "firewall_analytics_daily_quota_gbs" {
  type        = number
  default     = 1
  description = "The daily quota in GBs for the Log Analytics workspace"
}

# Common tags
variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags that will be applied to all resources in this module"
}

# Generic Firewall Rules Configuration
variable "network_groups" {
  type = map(object({
    name             = string
    address_prefixes = list(string)
    description      = optional(string)
  }))
  default     = {}
  description = "Map of network groups with their CIDR ranges"
}

variable "network_policies" {
  type = map(object({
    network_group_keys = list(string)
    egress_policy      = string
    priority_base      = number
    description        = optional(string)
    allowed_destinations = optional(object({
      fqdns     = optional(list(string), [])
      addresses = optional(list(string), [])
      ports     = optional(list(string), ["443", "80"])
      protocols = optional(list(string), ["TCP"])
    }))
    blocked_destinations = optional(object({
      fqdns     = optional(list(string), [])
      addresses = optional(list(string), [])
      ports     = optional(list(string), [])
      protocols = optional(list(string), [])
    }))
  }))
  default     = {}
  description = "Map of network policies defining egress behavior per environment"
  validation {
    condition = alltrue([
      for k, v in var.network_policies : contains([
        "allow_all_logged", 
        "explicit_allow_only", 
        "deny_all"
      ], v.egress_policy)
    ])
    error_message = "Egress policy must be one of: allow_all_logged, explicit_allow_only, deny_all."
  }
}

variable "default_egress_policy" {
  type = object({
    action          = string
    priority        = number
    log_traffic     = optional(bool, true)
    description     = optional(string, "Default egress policy for unmatched traffic")
  })
  default = {
    action      = "Deny"
    priority    = 900
    log_traffic = true
  }
  description = "Default egress policy for traffic not matching any specific network policy"
  validation {
    condition     = contains(["Allow", "Deny"], var.default_egress_policy.action)
    error_message = "Default egress policy action must be either 'Allow' or 'Deny'."
  }
}

variable "custom_application_rules" {
  type = map(object({
    name        = string
    priority    = number
    action      = string
    description = optional(string)
    rules = list(object({
      name             = string
      source_addresses = optional(list(string))
      source_ip_groups = optional(list(string))
      destination_fqdns = optional(list(string))
      destination_addresses = optional(list(string))
      destination_urls = optional(list(string))
      protocols = list(object({
        port = string
        type = string
      }))
      web_categories           = optional(list(string))
      terminate_tls           = optional(bool, false)
      http_headers            = optional(list(object({
        name  = string
        value = string
      })))
    }))
  }))
  default     = {}
  description = "Map of custom application rule collections"
  validation {
    condition = alltrue([
      for k, v in var.custom_application_rules : contains(["Allow", "Deny"], v.action)
    ])
    error_message = "Action must be either 'Allow' or 'Deny'."
  }
  validation {
    condition = alltrue([
      for k, v in var.custom_application_rules : alltrue([
        for rule in v.rules : alltrue([
          for protocol in rule.protocols : contains(["Http", "Https"], protocol.type)
        ])
      ])
    ])
    error_message = "Protocol type must be either 'Http' or 'Https'."
  }
}

variable "custom_network_rules" {
  type = map(object({
    name        = string
    priority    = number
    action      = string
    description = optional(string)
    rules = list(object({
      name                  = string
      source_addresses      = optional(list(string))
      source_ip_groups      = optional(list(string))
      destination_addresses = optional(list(string))
      destination_ip_groups = optional(list(string))
      destination_fqdns     = optional(list(string))
      destination_ports     = list(string)
      protocols             = list(string)
    }))
  }))
  default     = {}
  description = "Map of custom network rule collections"
  validation {
    condition = alltrue([
      for k, v in var.custom_network_rules : contains(["Allow", "Deny"], v.action)
    ])
    error_message = "Action must be either 'Allow' or 'Deny'."
  }
  validation {
    condition = alltrue([
      for k, v in var.custom_network_rules : alltrue([
        for rule in v.rules : alltrue([
          for protocol in rule.protocols : contains(["TCP", "UDP", "ICMP", "Any"], protocol)
        ])
      ])
    ])
    error_message = "Protocol must be one of: TCP, UDP, ICMP, Any."
  }
}

variable "custom_nat_rules" {
  type = map(object({
    name        = string
    priority    = number
    action      = string
    description = optional(string)
    rules = list(object({
      name                = string
      source_addresses    = optional(list(string))
      source_ip_groups    = optional(list(string))
      destination_address = string
      destination_ports   = list(string)
      protocols           = list(string)
      translated_address  = string
      translated_port     = string
    }))
  }))
  default     = {}
  description = "Map of custom NAT rule collections"
  validation {
    condition = alltrue([
      for k, v in var.custom_nat_rules : v.action == "Dnat"
    ])
    error_message = "NAT rule collection action must be 'Dnat'."
  }
  validation {
    condition = alltrue([
      for k, v in var.custom_nat_rules : alltrue([
        for rule in v.rules : alltrue([
          for protocol in rule.protocols : contains(["TCP", "UDP"], protocol)
        ])
      ])
    ])
    error_message = "NAT rule protocols must be either 'TCP' or 'UDP'."
  }
}

