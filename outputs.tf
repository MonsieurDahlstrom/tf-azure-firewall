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
  value       = azurerm_firewall.digital_hub.virtual_hub[0].private_ip_address
}

output "firewall_policy_id" {
  description = "The ID of the Azure Firewall Policy"
  value       = azurerm_firewall_policy.digital_hub.id
}

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