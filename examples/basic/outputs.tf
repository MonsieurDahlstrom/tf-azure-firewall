output "firewall_id" {
  description = "The ID of the Azure Firewall"
  value       = module.firewall.firewall_id
}

output "firewall_name" {
  description = "The name of the Azure Firewall"
  value       = module.firewall.firewall_name
}

output "firewall_private_ip_address" {
  description = "The private IP address of the firewall in the virtual hub"
  value       = module.firewall.firewall_private_ip_address
}

output "firewall_policy_id" {
  description = "The ID of the Azure Firewall Policy"
  value       = module.firewall.firewall_policy_id
}

 