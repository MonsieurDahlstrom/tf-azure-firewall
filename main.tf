# ==============================================================================
# LOCAL VALUES
# ==============================================================================

locals {
  # Validation checks for hub VNET mode
  validation_errors = [
    !var.hub_vnet_config.create_vnet && var.existing_hub_vnet_id == null ? "existing_hub_vnet_id is required when create_vnet is false" : null,
    !var.hub_vnet_config.create_vnet && var.existing_firewall_subnet_id == null ? "existing_firewall_subnet_id is required when create_vnet is false" : null,
    var.firewall_config.forced_tunneling && !var.hub_vnet_config.create_vnet && var.existing_management_subnet_id == null ? "existing_management_subnet_id is required when forced_tunneling is enabled and create_vnet is false" : null,
  ]

  # Filter out null validation errors
  actual_validation_errors = [for error in local.validation_errors : error if error != null]

  # Network Policy Implementation
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

# ==============================================================================
# HUB VIRTUAL NETWORK INFRASTRUCTURE
# ==============================================================================

# Create Hub Virtual Network (if required)
resource "azurerm_virtual_network" "hub" {
  count               = var.hub_vnet_config.create_vnet ? 1 : 0
  name                = var.hub_vnet_config.vnet_name
  address_space       = var.hub_vnet_config.address_space
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
  lifecycle { ignore_changes = [tags["created_on"]] }
}

# Create AzureFirewallSubnet
resource "azurerm_subnet" "firewall" {
  count                = var.hub_vnet_config.create_vnet ? 1 : 0
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub[0].name
  address_prefixes     = [var.hub_vnet_config.firewall_subnet_cidr]
}

# Create AzureFirewallManagementSubnet (for forced tunneling if enabled)
resource "azurerm_subnet" "firewall_management" {
  count                = var.hub_vnet_config.create_vnet && var.firewall_config.forced_tunneling ? 1 : 0
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub[0].name
  address_prefixes     = [var.hub_vnet_config.management_subnet_cidr]
}

# Create Public IP addresses for Azure Firewall
resource "azurerm_public_ip" "firewall" {
  count               = var.firewall_config.public_ip_count
  name                = length(var.firewall_config.public_ip_names) > count.index ? var.firewall_config.public_ip_names[count.index] : "${var.firewall_config.name}-pip-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.firewall_config.zones

  tags = var.tags
  lifecycle { ignore_changes = [tags["created_on"]] }
}

# Create Public IP for management interface (forced tunneling)
resource "azurerm_public_ip" "firewall_management" {
  count               = var.firewall_config.forced_tunneling ? 1 : 0
  name                = "${var.firewall_config.name}-mgmt-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.firewall_config.zones

  tags = var.tags
  lifecycle { ignore_changes = [tags["created_on"]] }
}

# ==============================================================================
# AZURE FIREWALL POLICY AND CORE RESOURCES
# ==============================================================================

resource "azurerm_firewall_policy" "digital_hub" {
  name                = "${var.firewall_config.name}-policy"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.firewall_config.sku_tier

  # DNS configuration
  dynamic "dns" {
    for_each = length(var.firewall_config.dns_servers) > 0 ? [1] : []
    content {
      servers       = var.firewall_config.dns_servers
      proxy_enabled = true
    }
  }

  # Threat intelligence configuration - set to Deny for security compliance
  threat_intelligence_mode = var.firewall_config.threat_intel_mode != null ? var.firewall_config.threat_intel_mode : "Deny"

  # Private IP ranges configuration
  private_ip_ranges = length(var.firewall_config.private_ip_ranges) > 0 ? var.firewall_config.private_ip_ranges : null

  # IDPS (Intrusion Detection and Prevention System) configuration for security compliance
  dynamic "intrusion_detection" {
    for_each = var.firewall_config.sku_tier == "Premium" ? [1] : []
    content {
      mode = "Deny"
      dynamic "signature_overrides" {
        for_each = var.firewall_config.idps_signature_overrides != null ? var.firewall_config.idps_signature_overrides : []
        content {
          id    = signature_overrides.value.id
          state = signature_overrides.value.state
        }
      }
      dynamic "traffic_bypass" {
        for_each = var.firewall_config.idps_traffic_bypass != null ? var.firewall_config.idps_traffic_bypass : []
        content {
          name                  = traffic_bypass.value.name
          protocol              = traffic_bypass.value.protocol
          description           = traffic_bypass.value.description
          destination_addresses = traffic_bypass.value.destination_addresses
          destination_ip_groups = traffic_bypass.value.destination_ip_groups
          destination_ports     = traffic_bypass.value.destination_ports
          source_addresses      = traffic_bypass.value.source_addresses
          source_ip_groups      = traffic_bypass.value.source_ip_groups
        }
      }
    }
  }

  tags = var.tags
  lifecycle { ignore_changes = [tags["created_on"]] }
}

resource "azurerm_firewall" "digital_hub" {
  name                = var.firewall_config.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_config.sku_tier
  firewall_policy_id  = azurerm_firewall_policy.digital_hub.id
  zones               = var.firewall_config.zones

  # Main IP configuration
  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.hub_vnet_config.create_vnet ? azurerm_subnet.firewall[0].id : var.existing_firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }

  # Additional IP configurations for scale
  dynamic "ip_configuration" {
    for_each = range(1, var.firewall_config.public_ip_count)
    content {
      name                 = "configuration-${ip_configuration.value + 1}"
      public_ip_address_id = azurerm_public_ip.firewall[ip_configuration.value].id
    }
  }

  # Management IP configuration (for forced tunneling)
  dynamic "management_ip_configuration" {
    for_each = var.firewall_config.forced_tunneling ? [1] : []
    content {
      name                 = "management"
      subnet_id            = var.hub_vnet_config.create_vnet ? azurerm_subnet.firewall_management[0].id : var.existing_management_subnet_id
      public_ip_address_id = azurerm_public_ip.firewall_management[0].id
    }
  }

  tags = var.tags
  lifecycle { ignore_changes = [tags["created_on"]] }
}

# ==============================================================================
# FIREWALL RULES CONFIGURATION
# ==============================================================================

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
        name             = rule.value.name
        source_addresses = rule.value.source_addresses
        source_ip_groups = rule.value.source_ip_groups != null ? [
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
        name             = rule.value.name
        source_addresses = rule.value.source_addresses
        source_ip_groups = rule.value.source_ip_groups != null ? [
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
        name             = rule.value.name
        source_addresses = rule.value.source_addresses
        source_ip_groups = rule.value.source_ip_groups != null ? [
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
        type = "Http"
        port = 80
      }

      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  # Allow all other traffic as network rules
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

# Explicit Allow Only Policies - Production environments
resource "azurerm_firewall_policy_rule_collection_group" "explicit_allow_only_policies" {
  for_each = local.explicit_allow_only_policies

  name               = "policy-${each.key}-explicit-allow"
  firewall_policy_id = azurerm_firewall_policy.digital_hub.id
  priority           = each.value.priority_base

  # Allowed destinations application rules
  dynamic "application_rule_collection" {
    for_each = each.value.allowed_destinations != null && length(each.value.allowed_destinations.fqdns) > 0 ? [1] : []

    content {
      name     = "${each.key}-allowed-apps"
      priority = each.value.priority_base
      action   = "Allow"

      rule {
        name              = "allowed-fqdns"
        source_ip_groups  = local.network_policy_sources[each.key]
        destination_fqdns = each.value.allowed_destinations.fqdns

        dynamic "protocols" {
          for_each = each.value.allowed_destinations.protocols
          content {
            type = title(protocols.value)
            port = contains(each.value.allowed_destinations.ports, "443") && protocols.value == "TCP" ? 443 : (
              contains(each.value.allowed_destinations.ports, "80") && protocols.value == "TCP" ? 80 :
              tonumber(each.value.allowed_destinations.ports[0])
            )
          }
        }
      }
    }
  }

  # Allowed destinations network rules
  dynamic "network_rule_collection" {
    for_each = each.value.allowed_destinations != null && length(each.value.allowed_destinations.addresses) > 0 ? [1] : []

    content {
      name     = "${each.key}-allowed-networks"
      priority = each.value.priority_base + 1
      action   = "Allow"

      rule {
        name                  = "allowed-addresses"
        source_ip_groups      = local.network_policy_sources[each.key]
        destination_addresses = each.value.allowed_destinations.addresses
        destination_ports     = each.value.allowed_destinations.ports
        protocols             = each.value.allowed_destinations.protocols
      }
    }
  }

  # Blocked destinations (explicit deny)
  dynamic "application_rule_collection" {
    for_each = each.value.blocked_destinations != null && length(each.value.blocked_destinations.fqdns) > 0 ? [1] : []

    content {
      name     = "${each.key}-blocked-apps"
      priority = each.value.priority_base + 10
      action   = "Deny"

      rule {
        name              = "blocked-fqdns"
        source_ip_groups  = local.network_policy_sources[each.key]
        destination_fqdns = each.value.blocked_destinations.fqdns

        dynamic "protocols" {
          for_each = length(each.value.blocked_destinations.protocols) > 0 ? each.value.blocked_destinations.protocols : ["TCP"]
          content {
            type = title(protocols.value)
            port = length(each.value.blocked_destinations.ports) > 0 ? tonumber(each.value.blocked_destinations.ports[0]) : 443
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
    name     = "${each.key}-deny-all-apps"
    priority = each.value.priority_base
    action   = "Deny"

    rule {
      name              = "deny-all-app-traffic"
      source_ip_groups  = local.network_policy_sources[each.key]
      destination_fqdns = ["*"]

      protocols {
        type = "Http"
        port = 80
      }

      protocols {
        type = "Https"
        port = 443
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

# Default Egress Policy
resource "azurerm_firewall_policy_rule_collection_group" "default_egress_policy" {
  name               = "default-egress-policy"
  firewall_policy_id = azurerm_firewall_policy.digital_hub.id
  priority           = var.default_egress_policy.priority

  # Default action for unmatched traffic
  network_rule_collection {
    name     = "default-egress"
    priority = var.default_egress_policy.priority
    action   = var.default_egress_policy.action

    rule {
      name                  = "default-rule"
      source_addresses      = ["*"]
      destination_addresses = ["*"]
      destination_ports     = ["*"]
      protocols             = ["Any"]
    }
  }
}

# ==============================================================================
# LOGGING AND MONITORING
# ==============================================================================

resource "azurerm_log_analytics_workspace" "firewall" {
  name                = "${var.firewall_config.name}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.firewall_analytics_retention_days
  daily_quota_gb      = var.firewall_analytics_daily_quota_gbs

  tags = var.tags
}

data "azurerm_monitor_diagnostic_categories" "hub" {
  resource_id = azurerm_firewall.digital_hub.id
}

resource "azurerm_monitor_diagnostic_setting" "fw" {
  name                       = "${var.firewall_config.name}-diagnostics"
  target_resource_id         = azurerm_firewall.digital_hub.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.firewall.id

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.hub.log_category_types
    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.hub.metrics
    content {
      category = enabled_metric.value
    }
  }
}

/*
  MODERN AZURE FIREWALL MONITORING APPROACH (2024+)
  
  This configuration uses the latest Azure Firewall monitoring standards:
  
  1. RESOURCE-SPECIFIC STRUCTURED LOGS:
     - Uses "Dedicated" destination type for resource-specific tables
     - Provides up to 80% cost reduction compared to legacy AzureDiagnostics
     - Enables better query performance and dedicated table schemas
     - Required for Policy Analytics and Security Copilot integration
  
  2. EMBEDDED WORKBOOKS (No custom deployment needed):
     - Microsoft now provides built-in workbooks accessible via:
       Azure Portal → Azure Firewall → Monitoring → Workbooks
     - Seven specialized tabs: Overview, Application Rules, Network Rules, 
       DNS Proxy, IDPS, Threat Intelligence, Investigation
     - Automatic updates and cross-firewall fleet analysis
     - No maintenance of custom JSON templates required
  
  3. ENHANCED CAPABILITIES:
     - Security Copilot integration for AI-powered threat analysis
     - Policy Analytics for rule optimization insights
     - Geographic traffic visualization
     - Threat intelligence enrichment
  
  4. LOG CATEGORIES EXPLAINED:
     - AZFWNetworkRule/ApplicationRule/NatRule: Core firewall rule logs
     - AZFWThreatIntel: Threat intelligence detections
     - AZFWIdpsSignature: Intrusion detection and prevention system logs
     - AZFWDnsQuery: DNS proxy activity
     - *Aggregation logs: Required for Policy Analytics
     - AZFWFatFlow: High-throughput connection analysis
     - AZFWFlowTrace: Detailed flow information
  
  ACCESSING WORKBOOKS:
  1. Navigate to Azure Firewall resource in Azure Portal
  2. Go to Monitoring → Workbooks
  3. Select from gallery or create custom workbooks
  
  OPTIONAL FEATURES:
  - Security Copilot: Requires proper licensing and RBAC permissions
  - Policy Analytics: Automatically enabled with aggregation logs
  - Basic Table Plan: Can be configured for additional cost savings (80% reduction)
    but incompatible with Policy Analytics and Security Copilot
  
  For more information, see:
  - https://docs.microsoft.com/en-us/azure/firewall/firewall-workbook
  - https://docs.microsoft.com/en-us/azure/firewall/firewall-structured-logs
*/ 