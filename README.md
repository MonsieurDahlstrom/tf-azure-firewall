# Azure Firewall Module

This module creates an Azure Firewall with policies, analytics, and monitoring for a Virtual WAN hub using a service-based toggle system for granular control.

## Features

- Azure Firewall with Virtual Hub integration
- Service-based firewall rule toggles for granular control
- Environment-specific rule configurations
- Comprehensive firewall policies organized by service categories:
  - **Core Infrastructure**: AKS, Azure services, DNS, VPN
  - **Source Control & CI/CD**: GitHub, GitLab
  - **Container Registries**: Docker Hub, MCR, GCR, GHCR, Quay
  - **Package Managers**: Helm, NPM, Snapcraft
  - **Content Management**: Contentful
  - **Authentication**: Auth0
  - **Communication**: Slack
  - **Development Tools**: Cypress, Optimizely
  - **API & GraphQL**: Apollo GraphQL
  - **Monitoring & Analytics**: Grafana, Rapid7
  - **Travel Industry APIs**: Amadeus, Deutsche Bahn, Sabre
  - **Payment Processing**: Adyen
  - **Email Services**: SendGrid
  - **CRM**: Salesforce
  - **CDN & Tunneling**: Cloudflare
  - **Recruitment**: Jobylon
  - **Azure PaaS Services**: Service Bus, App Configuration
- Log Analytics workspace for firewall monitoring
- Application Insights workbook for firewall analytics
- DNS proxy configuration

## Usage

For detailed configuration examples and policy-based scenarios, see [EXAMPLES.md](./EXAMPLES.md).

## Module Structure

```
tf-azure-firewall/
├── main.tf                           # Main firewall resources and policy configurations
├── variables.tf                      # Input variables and validation
├── outputs.tf                        # Output values
├── versions.tf                       # Provider requirements
├── README.md                         # This documentation
├── EXAMPLES.md                       # Policy-based configuration examples
├── LICENSE.md                        # License information
├── COMMERCIAL_LICENSE.md             # Commercial license details
├── .pre-commit-config.yaml           # Pre-commit hooks configuration
├── .tflint.hcl                      # TFLint configuration
├── .gitignore                        # Git ignore patterns
├── package.json                      # Node.js dependencies for tooling
├── examples/                         # Usage examples
│   └── basic/                       # Basic usage example
│       ├── main.tf                  # Example configuration
│       ├── variables.tf             # Example variables
│       ├── outputs.tf               # Example outputs
│       └── README.md                # Example documentation
├── tests/                           # Terraform tests
│   ├── firewall.tftest.hcl         # Test configurations
│   └── .auto.tfvars.json           # Test variables
└── .github/                         # GitHub workflows and templates
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | >= 4.0 |
| random | >= 3.7 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 4.0 |
| random | >= 3.7 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| resource_group_name | The name of the resource group | `string` | n/a | yes |
| location | The Azure region where resources will be created | `string` | n/a | yes |
| hub_vnet_config | Configuration for Hub Virtual Network | `object({...})` | See description | no |
| existing_hub_vnet_id | ID of existing hub virtual network (used when hub_vnet_config.create_vnet = false) | `string` | `null` | no |
| existing_firewall_subnet_id | ID of existing AzureFirewallSubnet (used when hub_vnet_config.create_vnet = false) | `string` | `null` | no |
| existing_management_subnet_id | ID of existing AzureFirewallManagementSubnet (used when hub_vnet_config.create_vnet = false) | `string` | `null` | no |
| firewall_config | Configuration for Azure Firewall. Note: IDPS features require Premium SKU tier for security compliance. | `object({...})` | See description | no |
| firewall_analytics_retention_days | The number of days to retain logs in the Log Analytics workspace | `number` | `30` | no |
| firewall_analytics_daily_quota_gbs | The daily quota in GBs for the Log Analytics workspace | `number` | `1` | no |
| tags | Tags that will be applied to all resources in this module | `map(string)` | `{}` | no |
| network_groups | Map of network groups with their CIDR ranges | `map(object({...}))` | `{}` | no |
| network_policies | Map of network policies defining egress behavior per environment | `map(object({...}))` | `{}` | no |
| default_egress_policy | Default egress policy for traffic not matching any specific network policy | `object({...})` | `{action = "Deny", priority = 900, log_traffic = true}` | no |
| custom_application_rules | Map of custom application rule collections | `map(object({...}))` | `{}` | no |
| custom_network_rules | Map of custom network rule collections | `map(object({...}))` | `{}` | no |
| custom_nat_rules | Map of custom NAT rule collections | `map(object({...}))` | `{}` | no |

### Complex Variable Details

#### hub_vnet_config
```hcl
hub_vnet_config = {
  vnet_name              = "hub-vnet"           # Name of the virtual network
  address_space          = ["10.0.0.0/16"]     # Address space for the VNet
  firewall_subnet_cidr   = "10.0.1.0/26"       # CIDR for AzureFirewallSubnet
  management_subnet_cidr = "10.0.2.0/26"       # CIDR for AzureFirewallManagementSubnet
  create_vnet            = true                 # Whether to create a new VNet
}
```

#### firewall_config
```hcl
firewall_config = {
  name                     = "azure-firewall"  # Name of the firewall
  sku_tier                 = "Standard"        # SKU tier: Standard or Premium
  threat_intel_mode        = "Deny"            # Threat intelligence mode
  public_ip_count          = 1                 # Number of public IPs
  public_ip_names          = []                # Custom public IP names
  zones                    = []                # Availability zones
  forced_tunneling         = false             # Enable forced tunneling
  dns_servers              = []                # Custom DNS servers
  private_ip_ranges        = []                # Private IP ranges for SNAT
  idps_signature_overrides = []                # IDPS signature overrides (Premium only)
  idps_traffic_bypass      = []                # IDPS traffic bypass rules (Premium only)
}
```

#### network_groups
```hcl
network_groups = {
  "production" = {
    name             = "Production Network"
    address_prefixes = ["10.1.0.0/16", "10.2.0.0/16"]
    description      = "Production environment networks"
  }
}
```

#### network_policies
```hcl
network_policies = {
  "production_policy" = {
    network_group_keys = ["production"]
    egress_policy      = "explicit_allow_only"  # allow_all_logged, explicit_allow_only, deny_all
    priority_base      = 100
    description        = "Production security policy"
    allowed_destinations = {
      fqdns     = ["api.example.com"]
      addresses = ["8.8.8.8"]
      ports     = ["443", "80"]
      protocols = ["TCP"]
    }
    blocked_destinations = {
      fqdns     = ["malicious.com"]
      addresses = ["192.168.100.0/24"]
      ports     = ["22"]
      protocols = ["TCP"]
    }
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| firewall_id | The ID of the Azure Firewall |
| firewall_name | The name of the Azure Firewall |
| firewall_private_ip_address | The private IP address of the Azure Firewall |
| firewall_policy_id | The ID of the Azure Firewall Policy |
| log_analytics_workspace_id | The ID of the Log Analytics workspace for firewall analytics |
| log_analytics_workspace_name | The name of the Log Analytics workspace for firewall analytics |

## Benefits of the Service-Based Structure

1. **Granular Control**: Enable only the services you need
2. **Environment-Specific**: Different rule sets for dev/staging/production
3. **Cost Optimization**: Fewer rules = better performance and lower costs
4. **Security**: Principle of least privilege - only allow what's needed
5. **Maintainability**: Organized by service categories for easier management
6. **Documentation**: Clear understanding of what each toggle enables
7. **Flexibility**: Easy to add or remove services as requirements change

## Best Practices

### Security
- Start with core services only and add business services as needed
- Use environment-specific source addresses to limit rule scope
- Regularly review enabled services and disable unused ones

### Cost Optimization
- Disable services not needed in development environments
- Use specific source addresses instead of wildcard `["*"]` where possible
- Monitor firewall analytics to identify unused rules

### Maintenance
- Document which services your applications actually use
- Use descriptive names when customizing source addresses
- Keep environment-specific configurations in separate variable files


## 📜 License

This module is licensed under the [CC BY-NC 4.0 license](https://creativecommons.org/licenses/by-nc/4.0/).  
You may use, modify, and share this code **for non-commercial purposes only**.

If you wish to use it in a commercial project (e.g., as part of client infrastructure or a paid product), you must obtain a commercial license.

📬 Contact: mathias@monsieurdahlstrom.com