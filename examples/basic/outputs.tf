output "firewall_id" {
  description = "The ID of the Azure Firewall"
  value       = module.firewall.firewall_id
}

output "firewall_name" {
  description = "The name of the Azure Firewall"
  value       = module.firewall.firewall_name
}

output "firewall_private_ip_address" {
  description = "The private IP address of the Azure Firewall"
  value       = module.firewall.firewall_private_ip_address
}

output "firewall_public_ip_addresses" {
  description = "List of public IP addresses assigned to the Azure Firewall"
  value       = module.firewall.firewall_public_ip_addresses
}

output "hub_virtual_network_id" {
  description = "The ID of the hub virtual network"
  value       = module.firewall.hub_virtual_network_id
}

output "hub_virtual_network_name" {
  description = "The name of the hub virtual network"
  value       = module.firewall.hub_virtual_network_name
}

output "firewall_subnet_id" {
  description = "The ID of the AzureFirewallSubnet"
  value       = module.firewall.firewall_subnet_id
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace for firewall analytics"
  value       = module.firewall.log_analytics_workspace_id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace for firewall analytics"
  value       = module.firewall.log_analytics_workspace_name
}

output "firewall_policy_id" {
  description = "The ID of the Azure Firewall Policy"
  value       = module.firewall.firewall_policy_id
}

 