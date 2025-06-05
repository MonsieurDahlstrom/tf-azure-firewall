# Resource Group variables
variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The Azure region where resources will be created"
}

# Virtual Hub variables
variable "virtual_hub_id" {
  type        = string
  description = "The ID of the virtual hub"
}

# DNS Resolver variables
variable "dns_resolver_private_ip" {
  type        = string
  description = "The private IP address of the DNS resolver inbound endpoint"
}

# GitHub Runner Network variables
variable "github_runner_network_address_space" {
  type        = list(string)
  description = "The address space of the GitHub runner network"
}

variable "github_runner_network_id" {
  type        = string
  description = "The ID of the GitHub runner virtual network"
}

# VPN Network variables
variable "vpn_network_address_space" {
  type        = string
  description = "The address space of the VPN network"
}

# Firewall configuration variables
variable "sku_tier" {
  type        = string
  default     = "Standard"
  description = "The SKU tier for the firewall"
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
    error_message = "NAT rules action must be 'Dnat'."
  }
  validation {
    condition = alltrue([
      for k, v in var.custom_nat_rules : alltrue([
        for rule in v.rules : alltrue([
          for protocol in rule.protocols : contains(["TCP", "UDP"], protocol)
        ])
      ])
    ])
    error_message = "NAT rule protocols must be TCP or UDP."
  }
}

