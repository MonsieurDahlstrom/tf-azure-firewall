run "firewall_plan_validation" {
  command = plan
  module {
    source = "./examples/basic"
  }

  variables {
    resource_group_name = "rg-firewall-plan-test"
    environment        = "plan-test"
  }

  # Simple validation that the plan succeeds without errors
  # The apply tests validate actual resource creation
}

run "premium_firewall_plan" {
  command = plan
  module {
    source = "./examples/basic"
  }

  variables {
    firewall_sku_tier   = "Premium"
    resource_group_name = "rg-firewall-premium-plan"
    environment        = "premium-plan"
  }

  # Validate Premium SKU configuration can be planned successfully
  # This ensures IDPS configuration is valid without provisioning
}

run "comprehensive_firewall_test" {
  command = apply
  module {
    source = "./examples/basic"
  }

  variables {
    firewall_sku_tier   = "Premium"
    resource_group_name = "rg-firewall-comprehensive-test"
    environment        = "comprehensive-test"
  }

  # Core functionality assertions
  assert {
    condition     = module.firewall.firewall_id != null
    error_message = "Azure Firewall should be created"
  }

  assert {
    condition     = module.firewall.firewall_name != null
    error_message = "Azure Firewall should have a name"
  }

  assert {
    condition     = module.firewall.firewall_policy_id != null
    error_message = "Firewall policy should be created"
  }

  # Network infrastructure assertions
  assert {
    condition     = module.firewall.hub_virtual_network_id != null
    error_message = "Hub virtual network should be created"
  }

  assert {
    condition     = module.firewall.firewall_subnet_id != null
    error_message = "Firewall subnet should be created"
  }

  # Output validation assertions
  assert {
    condition     = module.firewall.firewall_private_ip_address != null && module.firewall.firewall_private_ip_address != ""
    error_message = "firewall_private_ip_address output should not be null or empty"
  }

  assert {
    condition     = can(cidrnetmask("${module.firewall.firewall_private_ip_address}/32"))
    error_message = "firewall_private_ip_address should be a valid IP address"
  }

  assert {
    condition     = length(module.firewall.firewall_public_ip_addresses) > 0
    error_message = "Firewall should have at least one public IP address"
  }

  assert {
    condition     = length(module.firewall.firewall_public_ip_ids) > 0
    error_message = "firewall_public_ip_ids should contain at least one resource ID"
  }

  assert {
    condition     = module.firewall.log_analytics_workspace_id != null
    error_message = "Log Analytics workspace should be created"
  }

  assert {
    condition     = module.firewall.hub_virtual_network_name != null && module.firewall.hub_virtual_network_name != ""
    error_message = "hub_virtual_network_name output should not be null or empty"
  }

  assert {
    condition     = module.firewall.firewall_subnet_id != null && module.firewall.firewall_subnet_id != ""
    error_message = "firewall_subnet_id output should not be null or empty"
  }

  assert {
    condition     = module.firewall.log_analytics_workspace_name != null && module.firewall.log_analytics_workspace_name != ""
    error_message = "log_analytics_workspace_name output should not be null or empty"
  }
}




