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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.7 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.31.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_firewall.digital_hub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall) | resource |
| [azurerm_firewall_policy.digital_hub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy) | resource |
| [azurerm_firewall_policy_rule_collection_group.allow_all_logged_policies](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy_rule_collection_group) | resource |
| [azurerm_firewall_policy_rule_collection_group.custom_application_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy_rule_collection_group) | resource |
| [azurerm_firewall_policy_rule_collection_group.custom_nat_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy_rule_collection_group) | resource |
| [azurerm_firewall_policy_rule_collection_group.custom_network_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy_rule_collection_group) | resource |
| [azurerm_firewall_policy_rule_collection_group.default_egress_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy_rule_collection_group) | resource |
| [azurerm_firewall_policy_rule_collection_group.deny_all_policies](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy_rule_collection_group) | resource |
| [azurerm_firewall_policy_rule_collection_group.explicit_allow_only_policies](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy_rule_collection_group) | resource |
| [azurerm_ip_group.network_groups](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/ip_group) | resource |
| [azurerm_log_analytics_workspace.firewall](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_monitor_diagnostic_setting.fw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_public_ip.firewall](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.firewall_management](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_subnet.firewall](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.firewall_management](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_virtual_network.hub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_monitor_diagnostic_categories.hub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/monitor_diagnostic_categories) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_custom_application_rules"></a> [custom\_application\_rules](#input\_custom\_application\_rules) | Map of custom application rule collections | <pre>map(object({<br>    name        = string<br>    priority    = number<br>    action      = string<br>    description = optional(string)<br>    rules = list(object({<br>      name                  = string<br>      source_addresses      = optional(list(string))<br>      source_ip_groups      = optional(list(string))<br>      destination_fqdns     = optional(list(string))<br>      destination_addresses = optional(list(string))<br>      destination_urls      = optional(list(string))<br>      protocols = list(object({<br>        port = string<br>        type = string<br>      }))<br>      web_categories = optional(list(string))<br>      terminate_tls  = optional(bool, false)<br>      http_headers = optional(list(object({<br>        name  = string<br>        value = string<br>      })))<br>    }))<br>  }))</pre> | `{}` | no |
| <a name="input_custom_nat_rules"></a> [custom\_nat\_rules](#input\_custom\_nat\_rules) | Map of custom NAT rule collections | <pre>map(object({<br>    name        = string<br>    priority    = number<br>    action      = string<br>    description = optional(string)<br>    rules = list(object({<br>      name                = string<br>      source_addresses    = optional(list(string))<br>      source_ip_groups    = optional(list(string))<br>      destination_address = string<br>      destination_ports   = list(string)<br>      protocols           = list(string)<br>      translated_address  = string<br>      translated_port     = string<br>    }))<br>  }))</pre> | `{}` | no |
| <a name="input_custom_network_rules"></a> [custom\_network\_rules](#input\_custom\_network\_rules) | Map of custom network rule collections | <pre>map(object({<br>    name        = string<br>    priority    = number<br>    action      = string<br>    description = optional(string)<br>    rules = list(object({<br>      name                  = string<br>      source_addresses      = optional(list(string))<br>      source_ip_groups      = optional(list(string))<br>      destination_addresses = optional(list(string))<br>      destination_ip_groups = optional(list(string))<br>      destination_fqdns     = optional(list(string))<br>      destination_ports     = list(string)<br>      protocols             = list(string)<br>    }))<br>  }))</pre> | `{}` | no |
| <a name="input_default_egress_policy"></a> [default\_egress\_policy](#input\_default\_egress\_policy) | Default egress policy for traffic not matching any specific network policy | <pre>object({<br>    action      = string<br>    priority    = number<br>    log_traffic = optional(bool, true)<br>    description = optional(string, "Default egress policy for unmatched traffic")<br>  })</pre> | <pre>{<br>  "action": "Deny",<br>  "log_traffic": true,<br>  "priority": 900<br>}</pre> | no |
| <a name="input_existing_firewall_subnet_id"></a> [existing\_firewall\_subnet\_id](#input\_existing\_firewall\_subnet\_id) | ID of existing AzureFirewallSubnet (used when hub\_vnet\_config.create\_vnet = false) | `string` | `null` | no |
| <a name="input_existing_hub_vnet_id"></a> [existing\_hub\_vnet\_id](#input\_existing\_hub\_vnet\_id) | ID of existing hub virtual network (used when hub\_vnet\_config.create\_vnet = false) | `string` | `null` | no |
| <a name="input_existing_management_subnet_id"></a> [existing\_management\_subnet\_id](#input\_existing\_management\_subnet\_id) | ID of existing AzureFirewallManagementSubnet (used when hub\_vnet\_config.create\_vnet = false) | `string` | `null` | no |
| <a name="input_firewall_analytics_daily_quota_gbs"></a> [firewall\_analytics\_daily\_quota\_gbs](#input\_firewall\_analytics\_daily\_quota\_gbs) | The daily quota in GBs for the Log Analytics workspace | `number` | `1` | no |
| <a name="input_firewall_analytics_retention_days"></a> [firewall\_analytics\_retention\_days](#input\_firewall\_analytics\_retention\_days) | The number of days to retain logs in the Log Analytics workspace | `number` | `30` | no |
| <a name="input_firewall_config"></a> [firewall\_config](#input\_firewall\_config) | Configuration for Azure Firewall. Note: IDPS features require Premium SKU tier for security compliance. | <pre>object({<br>    name              = optional(string, "azure-firewall")<br>    sku_tier          = optional(string, "Standard")<br>    threat_intel_mode = optional(string, "Deny")<br>    public_ip_count   = optional(number, 1)<br>    public_ip_names   = optional(list(string), [])<br>    zones             = optional(list(string), [])<br>    forced_tunneling  = optional(bool, false)<br>    dns_servers       = optional(list(string), [])<br>    private_ip_ranges = optional(list(string), [])<br>    idps_signature_overrides = optional(list(object({<br>      id    = string<br>      state = string<br>    })), [])<br>    idps_traffic_bypass = optional(list(object({<br>      name                  = string<br>      protocol              = string<br>      description           = optional(string)<br>      destination_addresses = optional(list(string))<br>      destination_ip_groups = optional(list(string))<br>      destination_ports     = optional(list(string))<br>      source_addresses      = optional(list(string))<br>      source_ip_groups      = optional(list(string))<br>    })), [])<br>  })</pre> | <pre>{<br>  "dns_servers": [],<br>  "forced_tunneling": false,<br>  "idps_signature_overrides": [],<br>  "idps_traffic_bypass": [],<br>  "name": "azure-firewall",<br>  "private_ip_ranges": [],<br>  "public_ip_count": 1,<br>  "public_ip_names": [],<br>  "sku_tier": "Standard",<br>  "threat_intel_mode": "Deny",<br>  "zones": []<br>}</pre> | no |
| <a name="input_hub_vnet_config"></a> [hub\_vnet\_config](#input\_hub\_vnet\_config) | Configuration for Hub Virtual Network | <pre>object({<br>    vnet_name              = optional(string, "hub-vnet")<br>    address_space          = optional(list(string), ["10.0.0.0/16"])<br>    firewall_subnet_cidr   = optional(string, "10.0.1.0/26")<br>    management_subnet_cidr = optional(string, "10.0.2.0/26") # For forced tunneling<br>    create_vnet            = optional(bool, true)<br>  })</pre> | <pre>{<br>  "address_space": [<br>    "10.0.0.0/16"<br>  ],<br>  "create_vnet": true,<br>  "firewall_subnet_cidr": "10.0.1.0/26",<br>  "management_subnet_cidr": "10.0.2.0/26",<br>  "vnet_name": "hub-vnet"<br>}</pre> | no |
| <a name="input_location"></a> [location](#input\_location) | The Azure region where resources will be created | `string` | n/a | yes |
| <a name="input_network_groups"></a> [network\_groups](#input\_network\_groups) | Map of network groups with their CIDR ranges | <pre>map(object({<br>    name             = string<br>    address_prefixes = list(string)<br>    description      = optional(string)<br>  }))</pre> | `{}` | no |
| <a name="input_network_policies"></a> [network\_policies](#input\_network\_policies) | Map of network policies defining egress behavior per environment | <pre>map(object({<br>    network_group_keys = list(string)<br>    egress_policy      = string<br>    priority_base      = number<br>    description        = optional(string)<br>    allowed_destinations = optional(object({<br>      fqdns     = optional(list(string), [])<br>      addresses = optional(list(string), [])<br>      ports     = optional(list(string), ["443", "80"])<br>      protocols = optional(list(string), ["TCP"])<br>    }))<br>    blocked_destinations = optional(object({<br>      fqdns     = optional(list(string), [])<br>      addresses = optional(list(string), [])<br>      ports     = optional(list(string), [])<br>      protocols = optional(list(string), [])<br>    }))<br>  }))</pre> | `{}` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags that will be applied to all resources in this module | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_active_network_policies"></a> [active\_network\_policies](#output\_active\_network\_policies) | Summary of active network policies and their configurations |
| <a name="output_allow_all_logged_policy_groups"></a> [allow\_all\_logged\_policy\_groups](#output\_allow\_all\_logged\_policy\_groups) | Map of allow-all-logged policy rule collection groups and their IDs |
| <a name="output_application_rule_collection_groups"></a> [application\_rule\_collection\_groups](#output\_application\_rule\_collection\_groups) | Map of created application rule collection groups and their IDs |
| <a name="output_default_egress_policy_group"></a> [default\_egress\_policy\_group](#output\_default\_egress\_policy\_group) | Default egress policy rule collection group information |
| <a name="output_deny_all_policy_groups"></a> [deny\_all\_policy\_groups](#output\_deny\_all\_policy\_groups) | Map of deny-all policy rule collection groups and their IDs |
| <a name="output_explicit_allow_only_policy_groups"></a> [explicit\_allow\_only\_policy\_groups](#output\_explicit\_allow\_only\_policy\_groups) | Map of explicit-allow-only policy rule collection groups and their IDs |
| <a name="output_firewall_id"></a> [firewall\_id](#output\_firewall\_id) | The ID of the Azure Firewall |
| <a name="output_firewall_management_public_ip_address"></a> [firewall\_management\_public\_ip\_address](#output\_firewall\_management\_public\_ip\_address) | The management public IP address of the Azure Firewall (if forced tunneling is enabled) |
| <a name="output_firewall_management_subnet_id"></a> [firewall\_management\_subnet\_id](#output\_firewall\_management\_subnet\_id) | The ID of the AzureFirewallManagementSubnet (if created) |
| <a name="output_firewall_name"></a> [firewall\_name](#output\_firewall\_name) | The name of the Azure Firewall |
| <a name="output_firewall_policy_id"></a> [firewall\_policy\_id](#output\_firewall\_policy\_id) | The ID of the Azure Firewall Policy |
| <a name="output_firewall_private_ip_address"></a> [firewall\_private\_ip\_address](#output\_firewall\_private\_ip\_address) | The private IP address of the Azure Firewall |
| <a name="output_firewall_public_ip_addresses"></a> [firewall\_public\_ip\_addresses](#output\_firewall\_public\_ip\_addresses) | List of public IP addresses assigned to the Azure Firewall |
| <a name="output_firewall_public_ip_ids"></a> [firewall\_public\_ip\_ids](#output\_firewall\_public\_ip\_ids) | List of public IP resource IDs for the Azure Firewall |
| <a name="output_firewall_subnet_id"></a> [firewall\_subnet\_id](#output\_firewall\_subnet\_id) | The ID of the AzureFirewallSubnet |
| <a name="output_hub_virtual_network_id"></a> [hub\_virtual\_network\_id](#output\_hub\_virtual\_network\_id) | The ID of the hub virtual network |
| <a name="output_hub_virtual_network_name"></a> [hub\_virtual\_network\_name](#output\_hub\_virtual\_network\_name) | The name of the hub virtual network |
| <a name="output_ip_groups"></a> [ip\_groups](#output\_ip\_groups) | Map of created IP groups and their IDs |
| <a name="output_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#output\_log\_analytics\_workspace\_id) | The ID of the Log Analytics workspace for firewall analytics |
| <a name="output_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#output\_log\_analytics\_workspace\_name) | The name of the Log Analytics workspace for firewall analytics |
| <a name="output_nat_rule_collection_groups"></a> [nat\_rule\_collection\_groups](#output\_nat\_rule\_collection\_groups) | Map of created NAT rule collection groups and their IDs |
| <a name="output_network_rule_collection_groups"></a> [network\_rule\_collection\_groups](#output\_network\_rule\_collection\_groups) | Map of created network rule collection groups and their IDs |
<!-- END_TF_DOCS -->

## 📜 License

This module is licensed under the [CC BY-NC 4.0 license](https://creativecommons.org/licenses/by-nc/4.0/).  
You may use, modify, and share this code **for non-commercial purposes only**.

If you wish to use it in a commercial project (e.g., as part of client infrastructure or a paid product), you must obtain a commercial license.

📬 Contact: mathias@monsieurdahlstrom.com