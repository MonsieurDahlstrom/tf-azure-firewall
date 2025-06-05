# Hub Virtual Network Outputs
output "hub_virtual_network_id" {
  description = "The ID of the hub virtual network"
  value       = var.hub_vnet_config.create_vnet ? azurerm_virtual_network.hub[0].id : var.existing_hub_vnet_id
}

output "hub_virtual_network_name" {
  description = "The name of the hub virtual network"
  value       = var.hub_vnet_config.create_vnet ? azurerm_virtual_network.hub[0].name : null
}

output "firewall_subnet_id" {
  description = "The ID of the AzureFirewallSubnet"
  value       = var.hub_vnet_config.create_vnet ? azurerm_subnet.firewall[0].id : var.existing_firewall_subnet_id
}

output "firewall_management_subnet_id" {
  description = "The ID of the AzureFirewallManagementSubnet (if created)"
  value       = var.hub_vnet_config.create_vnet && var.firewall_config.forced_tunneling ? azurerm_subnet.firewall_management[0].id : var.existing_management_subnet_id
}

# Firewall Outputs
output "firewall_id" {
  description = "The ID of the Azure Firewall"
  value       = azurerm_firewall.digital_hub.id
}

output "firewall_name" {
  description = "The name of the Azure Firewall"
  value       = azurerm_firewall.digital_hub.name
}

output "firewall_private_ip_address" {
  description = "The private IP address of the Azure Firewall"
  value       = azurerm_firewall.digital_hub.ip_configuration[0].private_ip_address
}

output "firewall_public_ip_addresses" {
  description = "List of public IP addresses assigned to the Azure Firewall"
  value       = azurerm_public_ip.firewall[*].ip_address
}

output "firewall_public_ip_ids" {
  description = "List of public IP resource IDs for the Azure Firewall"
  value       = azurerm_public_ip.firewall[*].id
}

output "firewall_management_public_ip_address" {
  description = "The management public IP address of the Azure Firewall (if forced tunneling is enabled)"
  value       = var.firewall_config.forced_tunneling ? azurerm_public_ip.firewall_management[0].ip_address : null
}

output "firewall_policy_id" {
  description = "The ID of the Azure Firewall Policy"
  value       = azurerm_firewall_policy.digital_hub.id
}

# Monitoring Outputs
output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace for firewall analytics"
  value       = azurerm_log_analytics_workspace.firewall.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace for firewall analytics"
  value       = azurerm_log_analytics_workspace.firewall.name
}

# Generic Rules Outputs
output "ip_groups" {
  description = "Map of created IP groups and their IDs"
  value = {
    for k, v in azurerm_ip_group.network_groups : k => {
      id   = v.id
      name = v.name
      cidrs = v.cidrs
    }
  }
}

output "application_rule_collection_groups" {
  description = "Map of created application rule collection groups and their IDs"
  value = {
    for k, v in azurerm_firewall_policy_rule_collection_group.custom_application_rules : k => {
      id       = v.id
      name     = v.name
      priority = v.priority
    }
  }
}

output "network_rule_collection_groups" {
  description = "Map of created network rule collection groups and their IDs"
  value = {
    for k, v in azurerm_firewall_policy_rule_collection_group.custom_network_rules : k => {
      id       = v.id
      name     = v.name
      priority = v.priority
    }
  }
}

output "nat_rule_collection_groups" {
  description = "Map of created NAT rule collection groups and their IDs"
  value = {
    for k, v in azurerm_firewall_policy_rule_collection_group.custom_nat_rules : k => {
      id       = v.id
      name     = v.name
      priority = v.priority
    }
  }
}

# Network Policy Outputs
output "allow_all_logged_policy_groups" {
  description = "Map of allow-all-logged policy rule collection groups and their IDs"
  value = {
    for k, v in azurerm_firewall_policy_rule_collection_group.allow_all_logged_policies : k => {
      id       = v.id
      name     = v.name
      priority = v.priority
    }
  }
}

output "explicit_allow_only_policy_groups" {
  description = "Map of explicit-allow-only policy rule collection groups and their IDs"
  value = {
    for k, v in azurerm_firewall_policy_rule_collection_group.explicit_allow_only_policies : k => {
      id       = v.id
      name     = v.name
      priority = v.priority
    }
  }
}

output "deny_all_policy_groups" {
  description = "Map of deny-all policy rule collection groups and their IDs"
  value = {
    for k, v in azurerm_firewall_policy_rule_collection_group.deny_all_policies : k => {
      id       = v.id
      name     = v.name
      priority = v.priority
    }
  }
}

output "default_egress_policy_group" {
  description = "Default egress policy rule collection group information"
  value = {
    id       = azurerm_firewall_policy_rule_collection_group.default_egress_policy.id
    name     = azurerm_firewall_policy_rule_collection_group.default_egress_policy.name
    priority = azurerm_firewall_policy_rule_collection_group.default_egress_policy.priority
    action   = var.default_egress_policy.action
  }
}

output "active_network_policies" {
  description = "Summary of active network policies and their configurations"
  value = {
    for k, v in var.network_policies : k => {
      egress_policy      = v.egress_policy
      priority_base      = v.priority_base
      network_group_keys = v.network_group_keys
      description        = v.description
    }
  }
} 