# Firewall Rules Module - DISABLED
# The firewall rules module has been disabled as part of refactoring
# to move rule management outside of the firewall module itself

# module "firewall_rules" {
#   source = "../firewall-rules"
#
#   # Pass the firewall policy ID and location
#   firewall_policy_id = azurerm_firewall_policy.digital_hub.id
#   location           = var.location
#
#   # Network configuration
#   github_runner_network_address_space = var.github_runner_network_address_space
#   github_runner_network_id            = var.github_runner_network_id
#   vpn_network_address_space           = var.vpn_network_address_space
#
#   # Environment-specific source addresses
#   development_source_addresses = var.development_source_addresses
#   staging_source_addresses     = var.staging_source_addresses
#   production_source_addresses  = var.production_source_addresses
#
#   # Service toggle variables
#   enable_core_infrastructure_rules   = var.enable_core_infrastructure_rules
#   enable_source_control_rules        = var.enable_source_control_rules
#   enable_container_registry_rules    = var.enable_container_registry_rules
#   enable_package_manager_rules       = var.enable_package_manager_rules
#   enable_content_management_rules    = var.enable_content_management_rules
#   enable_authentication_rules        = var.enable_authentication_rules
#   enable_communication_rules         = var.enable_communication_rules
#   enable_development_tools_rules     = var.enable_development_tools_rules
#   enable_api_graphql_rules           = var.enable_api_graphql_rules
#   enable_monitoring_analytics_rules  = var.enable_monitoring_analytics_rules
#   enable_travel_industry_rules       = var.enable_travel_industry_rules
#   enable_payment_processing_rules    = var.enable_payment_processing_rules
#   enable_email_services_rules        = var.enable_email_services_rules
#   enable_crm_rules                   = var.enable_crm_rules
#   enable_cdn_tunneling_rules         = var.enable_cdn_tunneling_rules
#   enable_recruitment_rules           = var.enable_recruitment_rules
#   enable_azure_services_rules        = var.enable_azure_services_rules
# } 

# Generic Firewall Rules Implementation

# Create IP Groups for network groups
resource "azurerm_ip_group" "network_groups" {
  for_each = var.network_groups

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  cidrs               = each.value.address_prefixes

  tags = merge(var.tags, {
    Description = each.value.description != null ? each.value.description : "Network group for ${each.key}"
  })

  lifecycle { 
    ignore_changes = [tags["created_on"]] 
  }
}

# Custom Application Rule Collections
resource "azurerm_firewall_policy_rule_collection_group" "custom_application_rules" {
  for_each = var.custom_application_rules

  name               = each.key
  firewall_policy_id = azurerm_firewall_policy.digital_hub.id
  priority           = each.value.priority

  application_rule_collection {
    name     = each.value.name
    priority = each.value.priority
    action   = each.value.action

    dynamic "rule" {
      for_each = each.value.rules
      content {
        name              = rule.value.name
        source_addresses  = rule.value.source_addresses
        source_ip_groups  = rule.value.source_ip_groups != null ? [
          for ip_group in rule.value.source_ip_groups : 
          azurerm_ip_group.network_groups[ip_group].id
          if contains(keys(var.network_groups), ip_group)
        ] : null
        destination_fqdns     = rule.value.destination_fqdns
        destination_addresses = rule.value.destination_addresses
        destination_urls      = rule.value.destination_urls
        web_categories        = rule.value.web_categories
        terminate_tls         = rule.value.terminate_tls

        dynamic "protocols" {
          for_each = rule.value.protocols
          content {
            port = protocols.value.port
            type = protocols.value.type
          }
        }

        dynamic "http_headers" {
          for_each = rule.value.http_headers != null ? rule.value.http_headers : []
          content {
            name  = http_headers.value.name
            value = http_headers.value.value
          }
        }
      }
    }
  }
}

# Custom Network Rule Collections
resource "azurerm_firewall_policy_rule_collection_group" "custom_network_rules" {
  for_each = var.custom_network_rules

  name               = each.key
  firewall_policy_id = azurerm_firewall_policy.digital_hub.id
  priority           = each.value.priority

  network_rule_collection {
    name     = each.value.name
    priority = each.value.priority
    action   = each.value.action

    dynamic "rule" {
      for_each = each.value.rules
      content {
        name                  = rule.value.name
        source_addresses      = rule.value.source_addresses
        source_ip_groups      = rule.value.source_ip_groups != null ? [
          for ip_group in rule.value.source_ip_groups : 
          azurerm_ip_group.network_groups[ip_group].id
          if contains(keys(var.network_groups), ip_group)
        ] : null
        destination_addresses = rule.value.destination_addresses
        destination_ip_groups = rule.value.destination_ip_groups != null ? [
          for ip_group in rule.value.destination_ip_groups : 
          azurerm_ip_group.network_groups[ip_group].id
          if contains(keys(var.network_groups), ip_group)
        ] : null
        destination_fqdns = rule.value.destination_fqdns
        destination_ports = rule.value.destination_ports
        protocols         = rule.value.protocols
      }
    }
  }
}

# Custom NAT Rule Collections
resource "azurerm_firewall_policy_rule_collection_group" "custom_nat_rules" {
  for_each = var.custom_nat_rules

  name               = each.key
  firewall_policy_id = azurerm_firewall_policy.digital_hub.id
  priority           = each.value.priority

  nat_rule_collection {
    name     = each.value.name
    priority = each.value.priority
    action   = each.value.action

    dynamic "rule" {
      for_each = each.value.rules
      content {
        name                = rule.value.name
        source_addresses    = rule.value.source_addresses
        source_ip_groups    = rule.value.source_ip_groups != null ? [
          for ip_group in rule.value.source_ip_groups : 
          azurerm_ip_group.network_groups[ip_group].id
          if contains(keys(var.network_groups), ip_group)
        ] : null
        destination_address = rule.value.destination_address
        destination_ports   = rule.value.destination_ports
        protocols           = rule.value.protocols
        translated_address  = rule.value.translated_address
        translated_port     = rule.value.translated_port
      }
    }
  }
}

# Network Policy Implementation
locals {
  # Build source IP group references for each policy
  network_policy_sources = {
    for policy_name, policy in var.network_policies : policy_name => [
      for group_key in policy.network_group_keys : 
      azurerm_ip_group.network_groups[group_key].id
      if contains(keys(var.network_groups), group_key)
    ]
  }

  # Create rules based on policy types
  allow_all_logged_policies = {
    for k, v in var.network_policies : k => v if v.egress_policy == "allow_all_logged"
  }

  explicit_allow_only_policies = {
    for k, v in var.network_policies : k => v if v.egress_policy == "explicit_allow_only"
  }

  deny_all_policies = {
    for k, v in var.network_policies : k => v if v.egress_policy == "deny_all"
  }
}

# Allow All (Logged) Policies - Development environments
resource "azurerm_firewall_policy_rule_collection_group" "allow_all_logged_policies" {
  for_each = local.allow_all_logged_policies

  name               = "policy-${each.key}-allow-all-logged"
  firewall_policy_id = azurerm_firewall_policy.digital_hub.id
  priority           = each.value.priority_base

  # Allow all HTTP/HTTPS traffic (will be logged)
  application_rule_collection {
    name     = "${each.key}-allow-all-web"
    priority = each.value.priority_base
    action   = "Allow"

    rule {
      name             = "allow-all-web-traffic"
      source_ip_groups = local.network_policy_sources[each.key]
      destination_fqdns = ["*"]
      protocols {
        port = "443"
        type = "Https"
      }
      protocols {
        port = "80"
        type = "Http"
      }
    }
  }

  # Allow all network traffic (will be logged)
  network_rule_collection {
    name     = "${each.key}-allow-all-network"
    priority = each.value.priority_base + 1
    action   = "Allow"

    rule {
      name                  = "allow-all-network-traffic"
      source_ip_groups      = local.network_policy_sources[each.key]
      destination_addresses = ["*"]
      destination_ports     = ["*"]
      protocols             = ["Any"]
    }
  }
}

# Explicit Allow Only Policies - Staging/Production environments
resource "azurerm_firewall_policy_rule_collection_group" "explicit_allow_only_policies" {
  for_each = local.explicit_allow_only_policies

  name               = "policy-${each.key}-explicit-allow"
  firewall_policy_id = azurerm_firewall_policy.digital_hub.id
  priority           = each.value.priority_base

  # Allow only specified destinations
  dynamic "application_rule_collection" {
    for_each = each.value.allowed_destinations != null && length(each.value.allowed_destinations.fqdns) > 0 ? [1] : []
    content {
      name     = "${each.key}-allowed-web-destinations"
      priority = each.value.priority_base
      action   = "Allow"

      rule {
        name             = "allow-specified-fqdns"
        source_ip_groups = local.network_policy_sources[each.key]
        destination_fqdns = each.value.allowed_destinations.fqdns

        dynamic "protocols" {
          for_each = each.value.allowed_destinations.ports
          content {
            port = protocols.value
            type = protocols.value == "443" ? "Https" : "Http"
          }
        }
      }
    }
  }

  # Allow specified IP addresses
  dynamic "network_rule_collection" {
    for_each = each.value.allowed_destinations != null && length(each.value.allowed_destinations.addresses) > 0 ? [1] : []
    content {
      name     = "${each.key}-allowed-ip-destinations"
      priority = each.value.priority_base + 1
      action   = "Allow"

      rule {
        name                  = "allow-specified-ips"
        source_ip_groups      = local.network_policy_sources[each.key]
        destination_addresses = each.value.allowed_destinations.addresses
        destination_ports     = each.value.allowed_destinations.ports
        protocols             = each.value.allowed_destinations.protocols
      }
    }
  }

  # Explicitly block specified destinations (higher priority than allows)
  dynamic "application_rule_collection" {
    for_each = each.value.blocked_destinations != null && length(each.value.blocked_destinations.fqdns) > 0 ? [1] : []
    content {
      name     = "${each.key}-blocked-web-destinations"
      priority = each.value.priority_base - 10
      action   = "Deny"

      rule {
        name             = "block-specified-fqdns"
        source_ip_groups = local.network_policy_sources[each.key]
        destination_fqdns = each.value.blocked_destinations.fqdns

        dynamic "protocols" {
          for_each = length(each.value.blocked_destinations.ports) > 0 ? each.value.blocked_destinations.ports : ["443", "80"]
          content {
            port = protocols.value
            type = protocols.value == "443" ? "Https" : "Http"
          }
        }
      }
    }
  }
}

# Deny All Policies - Restricted environments
resource "azurerm_firewall_policy_rule_collection_group" "deny_all_policies" {
  for_each = local.deny_all_policies

  name               = "policy-${each.key}-deny-all"
  firewall_policy_id = azurerm_firewall_policy.digital_hub.id
  priority           = each.value.priority_base

  # Deny all application traffic
  application_rule_collection {
    name     = "${each.key}-deny-all-web"
    priority = each.value.priority_base
    action   = "Deny"

    rule {
      name             = "deny-all-web-traffic"
      source_ip_groups = local.network_policy_sources[each.key]
      destination_fqdns = ["*"]
      protocols {
        port = 443
        type = "Https"
      }
      protocols {
        port = 80
        type = "Http"
      }
    }
  }

  # Deny all network traffic
  network_rule_collection {
    name     = "${each.key}-deny-all-network"
    priority = each.value.priority_base + 1
    action   = "Deny"

    rule {
      name                  = "deny-all-network-traffic"
      source_ip_groups      = local.network_policy_sources[each.key]
      destination_addresses = ["*"]
      destination_ports     = ["*"]
      protocols             = ["Any"]
    }
  }
}

# Default Egress Policy - Catch-all rule for unmatched traffic
resource "azurerm_firewall_policy_rule_collection_group" "default_egress_policy" {
  name               = "default-egress-policy"
  firewall_policy_id = azurerm_firewall_policy.digital_hub.id
  priority           = var.default_egress_policy.priority

  # Default application rule
  application_rule_collection {
    name     = "default-application-policy"
    priority = var.default_egress_policy.priority
    action   = var.default_egress_policy.action

    rule {
      name             = "default-web-traffic"
      source_addresses = ["*"]
      destination_fqdns = ["*"]
      protocols {
        port = 443
        type = "Https"
      }
      protocols {
        port = 80
        type = "Http"
      }
    }
  }

  # Default network rule
  network_rule_collection {
    name     = "default-network-policy"
    priority = var.default_egress_policy.priority + 1
    action   = var.default_egress_policy.action

    rule {
      name                  = "default-network-traffic"
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["*"]
      protocols             = ["Any"]
    }
  }
} 