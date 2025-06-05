run "basic_firewall" {
  command = apply
  module {
    source = "./examples/basic"
  }

  assert {
    condition     = module.firewall.firewall_id != null
    error_message = "Azure Firewall should be created"
  }

  assert {
    condition     = module.firewall.firewall_name != null
    error_message = "Azure Firewall should have a name"
  }

  assert {
    condition     = module.firewall.firewall_private_ip_address != null
    error_message = "Firewall should have a private IP address"
  }

  assert {
    condition     = module.firewall.firewall_policy_id != null
    error_message = "Firewall policy should be created"
  }

  assert {
    condition     = module.firewall.hub_virtual_network_id != null
    error_message = "Hub virtual network should be created"
  }

  assert {
    condition     = module.firewall.firewall_subnet_id != null
    error_message = "Firewall subnet should be created"
  }

  assert {
    condition     = length(module.firewall.firewall_public_ip_addresses) > 0
    error_message = "Firewall should have at least one public IP address"
  }

  assert {
    condition     = module.firewall.log_analytics_workspace_id != null
    error_message = "Log Analytics workspace should be created for firewall monitoring"
  }
}

run "firewall_with_premium_sku" {
  command = apply
  module {
    source = "./examples/basic"
  }

  variables {
    firewall_sku_tier = "Premium"
  }

  assert {
    condition     = module.firewall.firewall_id != null
    error_message = "Azure Firewall should be created with Premium SKU"
  }

  assert {
    condition     = module.firewall.firewall_name != null
    error_message = "Azure Firewall should have a name"
  }

  assert {
    condition     = module.firewall.firewall_policy_id != null
    error_message = "Firewall policy should be created"
  }
}

run "firewall_output_validation" {
  command = apply
  module {
    source = "./examples/basic"
  }

  assert {
    condition     = module.firewall.firewall_id != null && module.firewall.firewall_id != ""
    error_message = "firewall_id output should not be null or empty"
  }

  assert {
    condition     = module.firewall.firewall_name != null && module.firewall.firewall_name != ""
    error_message = "firewall_name output should not be null or empty"
  }

  assert {
    condition     = module.firewall.firewall_private_ip_address != null && module.firewall.firewall_private_ip_address != ""
    error_message = "firewall_private_ip_address output should not be null or empty"
  }

  assert {
    condition     = module.firewall.firewall_policy_id != null && module.firewall.firewall_policy_id != ""
    error_message = "firewall_policy_id output should not be null or empty"
  }

  assert {
    condition     = can(cidrnetmask("${module.firewall.firewall_private_ip_address}/32"))
    error_message = "firewall_private_ip_address should be a valid IP address, got ${module.firewall.firewall_private_ip_address}"
  }

  assert {
    condition     = module.firewall.hub_virtual_network_id != null && module.firewall.hub_virtual_network_id != ""
    error_message = "hub_virtual_network_id output should not be null or empty"
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
    condition     = length(module.firewall.firewall_public_ip_addresses) > 0
    error_message = "firewall_public_ip_addresses should contain at least one IP address"
  }

  assert {
    condition     = length(module.firewall.firewall_public_ip_ids) > 0
    error_message = "firewall_public_ip_ids should contain at least one resource ID"
  }

  assert {
    condition     = module.firewall.log_analytics_workspace_id != null && module.firewall.log_analytics_workspace_id != ""
    error_message = "log_analytics_workspace_id output should not be null or empty"
  }

  assert {
    condition     = module.firewall.log_analytics_workspace_name != null && module.firewall.log_analytics_workspace_name != ""
    error_message = "log_analytics_workspace_name output should not be null or empty"
  }
}

run "firewall_plan_validation" {
  command = plan
  module {
    source = "./examples/basic"
  }

  # Validate that critical resources will be created
  assert {
    condition     = length([for r in planned_values.root_module.resources : r if r.type == "azurerm_firewall"]) > 0
    error_message = "Plan should include creating an Azure Firewall resource"
  }

  assert {
    condition     = length([for r in planned_values.root_module.resources : r if r.type == "azurerm_firewall_policy"]) > 0
    error_message = "Plan should include creating an Azure Firewall Policy resource"
  }

  assert {
    condition     = length([for r in planned_values.root_module.resources : r if r.type == "azurerm_virtual_network"]) > 0
    error_message = "Plan should include creating a Virtual Network resource"
  }

  assert {
    condition     = length([for r in planned_values.root_module.resources : r if r.type == "azurerm_log_analytics_workspace"]) > 0
    error_message = "Plan should include creating a Log Analytics Workspace resource"
  }
}


