resource "azurerm_log_analytics_workspace" "firewall" {
  name                = "digital-hub-firewall-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.firewall_analytics_retention_days
  daily_quota_gb      = var.firewall_analytics_daily_quota_gbs
}

data "azurerm_monitor_diagnostic_categories" "hub" {
  resource_id = azurerm_firewall.digital_hub.id
}

resource "azurerm_monitor_diagnostic_setting" "fw" {
  name                           = "diagnostic_setting"
  target_resource_id             = data.azurerm_monitor_diagnostic_categories.hub.resource_id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.firewall.id
  log_analytics_destination_type = "Dedicated" # Enable resource-specific logging

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.hub.metrics
    content {
      category = metric.value
    }
  }

  # Resource-specific structured logs - recommended approach
  # These provide better performance, cost savings (up to 80%), and enable modern features
  dynamic "enabled_log" {
    for_each = [
      "AZFWNetworkRule",                 # Network rule log data
      "AZFWApplicationRule",             # Application rule log data
      "AZFWNatRule",                     # NAT rule log data
      "AZFWThreatIntel",                 # Threat Intelligence events
      "AZFWIdpsSignature",               # IDPS signature matches
      "AZFWDnsQuery",                    # DNS proxy events
      "AZFWFqdnResolveFailure",          # FQDN resolution failures
      "AZFWApplicationRuleAggregation",  # Application rule aggregation for Policy Analytics
      "AZFWNetworkRuleAggregation",      # Network rule aggregation for Policy Analytics
      "AZFWNatRuleAggregation",          # NAT rule aggregation for Policy Analytics
      "AZFWFatFlow",                     # Top flows (fat flows) - high throughput connections
      "AZFWFlowTrace"                    # Flow trace information
    ]
    content {
      category = enabled_log.value
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
