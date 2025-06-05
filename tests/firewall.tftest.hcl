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
    error_message = "Firewall should have a private IP address in the virtual hub"
  }

  assert {
    condition     = module.firewall.firewall_policy_id != null
    error_message = "Firewall policy should be created"
  }
}

run "firewall_with_custom_sku" {
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
}

run "firewall_with_virtual_wan" {
  module {
    source = "./examples/basic"
  }

  assert {
    condition     = module.firewall.firewall_id != null
    error_message = "Firewall should be created in Virtual WAN hub"
  }

  assert {
    condition     = module.firewall.firewall_policy_id != null
    error_message = "Firewall policy should be associated with the firewall"
  }
}

run "firewall_output_validation" {
  module {
    source = "./examples/basic"
  }

  assert {
    condition     = output.firewall_id != null && output.firewall_id != ""
    error_message = "firewall_id output should not be null or empty"
  }

  assert {
    condition     = output.firewall_name != null && output.firewall_name != ""
    error_message = "firewall_name output should not be null or empty"
  }

  assert {
    condition     = output.firewall_private_ip_address != null && output.firewall_private_ip_address != ""
    error_message = "firewall_private_ip_address output should not be null or empty"
  }

  assert {
    condition     = output.firewall_policy_id != null && output.firewall_policy_id != ""
    error_message = "firewall_policy_id output should not be null or empty"
  }

  assert {
    condition     = can(cidrnetmask("${output.firewall_private_ip_address}/32"))
    error_message = "firewall_private_ip_address should be a valid IP address, got ${output.firewall_private_ip_address}"
  }
}
