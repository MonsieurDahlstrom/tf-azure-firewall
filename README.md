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

### Basic Usage with Core Services Only

```hcl
module "firewall" {
  source = "./modules/firewall"

  # Resource Group and Location
  resource_group_name = azurerm_resource_group.hub.name
  location           = azurerm_resource_group.hub.location

  # Virtual Hub
  virtual_hub_id = azurerm_virtual_hub.hub.id

  # DNS Configuration
  dns_resolver_private_ip = azurerm_private_dns_resolver_inbound_endpoint.dns_resolver_endpoint.ip_configurations[0].private_ip_address

  # GitHub Runner Network
  github_runner_network_address_space = azurerm_virtual_network.github_runner_network.address_space
  github_runner_network_id           = azurerm_virtual_network.github_runner_network.id

  # VPN Network
  vpn_network_address_space = local.vpn_network.address_space

  # Firewall Configuration
  sku_tier = var.sku_tier

  # Analytics Configuration
  firewall_analytics_retention_days     = var.firewall_analytics_retention_days
  firewall_analytics_daily_quota_gbs   = var.firewall_analytics_daily_quota_gbs

  # Service Toggles - Only enable core infrastructure
  enable_core_infrastructure_rules = true
  enable_source_control_rules      = true
  enable_container_registry_rules  = true
  enable_package_manager_rules     = true
  enable_azure_services_rules      = true

  # Disable optional services by default
  enable_content_management_rules    = false
  enable_authentication_rules        = false
  enable_communication_rules         = false
  enable_development_tools_rules     = false
  enable_api_graphql_rules           = false
  enable_monitoring_analytics_rules  = false
  enable_travel_industry_rules       = false
  enable_payment_processing_rules    = false
  enable_email_services_rules        = false
  enable_crm_rules                   = false
  enable_cdn_tunneling_rules         = false
  enable_recruitment_rules           = false

  # Tags
  tags = local.tags
}
```

### Production Usage with Business Services

```hcl
module "firewall" {
  source = "./modules/firewall"

  # ... basic configuration ...

  # Core services (typically always enabled)
  enable_core_infrastructure_rules = true
  enable_source_control_rules      = true
  enable_container_registry_rules  = true
  enable_package_manager_rules     = true
  enable_azure_services_rules      = true

  # Business services (enable as needed)
  enable_content_management_rules    = true  # Contentful
  enable_authentication_rules        = true  # Auth0
  enable_communication_rules         = true  # Slack
  enable_development_tools_rules     = true  # Cypress, Optimizely
  enable_api_graphql_rules           = true  # Apollo GraphQL
  enable_monitoring_analytics_rules  = true  # Grafana, Rapid7
  enable_travel_industry_rules       = true  # Amadeus, Deutsche Bahn, Sabre
  enable_payment_processing_rules    = true  # Adyen
  enable_email_services_rules        = true  # SendGrid
  enable_crm_rules                   = true  # Salesforce
  enable_cdn_tunneling_rules         = true  # Cloudflare
  enable_recruitment_rules           = true  # Jobylon

  # Environment-specific source addresses (customize as needed)
  development_source_addresses = ["10.163.0.0/18"]
  staging_source_addresses     = ["10.162.0.0/18"]
  production_source_addresses  = ["10.161.0.0/18"]
  production_vm_subnet_addresses = ["10.161.33.0/24"]

  tags = local.tags
}
```

### Development Environment Usage

```hcl
module "firewall" {
  source = "./modules/firewall"

  # ... basic configuration ...

  # Core services
  enable_core_infrastructure_rules = true
  enable_source_control_rules      = true
  enable_container_registry_rules  = true
  enable_package_manager_rules     = true

  # Development-specific services
  enable_content_management_rules = true
  enable_development_tools_rules  = true
  enable_api_graphql_rules        = true

  # Disable production services
  enable_travel_industry_rules    = false
  enable_payment_processing_rules = false
  enable_crm_rules                = false

  tags = local.tags
}
```

### Environment-Specific Configuration

```hcl
module "firewall" {
  source = "./modules/firewall"

  # ... basic configuration ...

  # Enable all services
  enable_core_infrastructure_rules   = true
  enable_source_control_rules        = true
  enable_container_registry_rules    = true
  enable_package_manager_rules       = true
  enable_content_management_rules    = true
  enable_authentication_rules        = true
  enable_communication_rules         = true
  enable_development_tools_rules     = true
  enable_api_graphql_rules           = true
  enable_monitoring_analytics_rules  = true
  enable_travel_industry_rules       = true
  enable_payment_processing_rules    = true
  enable_email_services_rules        = true
  enable_crm_rules                   = true
  enable_cdn_tunneling_rules         = true
  enable_recruitment_rules           = true
  enable_azure_services_rules        = true

  # Custom environment addresses
  development_source_addresses = ["10.163.0.0/18"]
  staging_source_addresses     = ["10.162.0.0/18"]
  production_source_addresses  = ["10.161.0.0/18"]
  production_vm_subnet_addresses = ["10.161.33.0/24"]

  tags = local.tags
}
```

## Service Categories

### Core Infrastructure (`enable_core_infrastructure_rules`)
**Default: `true`**
- AKS (Azure Kubernetes Service) rules
- VPN connectivity rules
- Basic networking (DNS, NTP, Azure service tags)

### Source Control & CI/CD (`enable_source_control_rules`)
**Default: `true`**
- GitHub (general, packages, runner-specific)
- GitLab
- Container registries via source control

### Container Registries (`enable_container_registry_rules`)
**Default: `true`**
- Docker Hub
- Microsoft Container Registry (MCR)
- Google Container Registry (GCR)
- GitHub Container Registry (GHCR)
- Quay.io
- Kubernetes registries

### Package Managers (`enable_package_manager_rules`)
**Default: `true`**
- Helm charts
- Bitnami charts
- External Secrets charts
- Artifact Hub
- Snapcraft

### Content Management (`enable_content_management_rules`)
**Default: `false`**
- Contentful (all variants and CDN)

### Authentication (`enable_authentication_rules`)
**Default: `false`**
- Auth0

### Communication (`enable_communication_rules`)
**Default: `false`**
- Slack webhooks

### Development Tools (`enable_development_tools_rules`)
**Default: `false`**
- Cypress (testing)
- Optimizely (A/B testing)

### API & GraphQL (`enable_api_graphql_rules`)
**Default: `false`**
- Apollo GraphQL (all endpoints)

### Monitoring & Analytics (`enable_monitoring_analytics_rules`)
**Default: `false`**
- Grafana
- Rapid7 logging

### Travel Industry APIs (`enable_travel_industry_rules`)
**Default: `false`**
- Amadeus (test and production)
- Deutsche Bahn
- Sabre
- Includes both application and network rules

### Payment Processing (`enable_payment_processing_rules`)
**Default: `false`**
- Adyen (test and live environments)

### Email Services (`enable_email_services_rules`)
**Default: `false`**
- SendGrid

### CRM (`enable_crm_rules`)
**Default: `false`**
- Salesforce (common, dev/staging, and production environments)

### CDN & Tunneling (`enable_cdn_tunneling_rules`)
**Default: `false`**
- Cloudflare tunnels and API

### Recruitment (`enable_recruitment_rules`)
**Default: `false`**
- Jobylon

### Azure PaaS Services (`enable_azure_services_rules`)
**Default: `true`**
- Azure Service Bus (environment-specific)
- Azure App Configuration

## Module Structure

```
modules/firewall/
├── 2.1-firewall.tf                    # Main firewall and policy resources
├── 2.3-firewall-analytics.tf          # Analytics and monitoring
├── rules-core-infrastructure.tf       # AKS and VPN rules
├── rules-source-control.tf            # GitHub and GitLab rules
├── rules-container-registries.tf      # Container registry rules
├── rules-package-managers.tf          # Package manager rules
├── rules-cdn-tunneling.tf             # Cloudflare rules
├── rules-saas-services.tf             # SaaS service rules
├── rules-business-services.tf         # Business service rules
├── rules-azure-services.tf            # Azure PaaS service rules
├── variables.tf                       # Input variables
├── outputs.tf                         # Output values
├── versions.tf                        # Provider requirements
├── README.md                          # This file
└── MIGRATION_INSTRUCTIONS.md          # Migration guide
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
| virtual_hub_id | The ID of the virtual hub | `string` | n/a | yes |
| dns_resolver_private_ip | The private IP address of the DNS resolver inbound endpoint | `string` | n/a | yes |
| github_runner_network_address_space | The address space of the GitHub runner network | `list(string)` | n/a | yes |
| github_runner_network_id | The ID of the GitHub runner virtual network | `string` | n/a | yes |
| vpn_network_address_space | The address space of the VPN network | `string` | n/a | yes |
| sku_tier | The SKU tier for the firewall | `string` | `"Standard"` | no |
| firewall_analytics_retention_days | The number of days to retain logs in the Log Analytics workspace | `number` | `30` | no |
| firewall_analytics_daily_quota_gbs | The daily quota in GBs for the Log Analytics workspace | `number` | `1` | no |
| tags | Tags that will be applied to all resources in this module | `map(string)` | `{}` | no |
| enable_core_infrastructure_rules | Enable core infrastructure rules (AKS, Azure services, DNS, VPN) | `bool` | `true` | no |
| enable_source_control_rules | Enable source control and CI/CD rules (GitHub, GitLab) | `bool` | `true` | no |
| enable_container_registry_rules | Enable container registry rules (Docker Hub, MCR, GCR, GHCR, Quay) | `bool` | `true` | no |
| enable_package_manager_rules | Enable package manager rules (Helm, NPM, Snapcraft) | `bool` | `true` | no |
| enable_content_management_rules | Enable content management rules (Contentful) | `bool` | `false` | no |
| enable_authentication_rules | Enable authentication service rules (Auth0) | `bool` | `false` | no |
| enable_communication_rules | Enable communication service rules (Slack) | `bool` | `false` | no |
| enable_development_tools_rules | Enable development tools rules (Cypress, Optimizely) | `bool` | `false` | no |
| enable_api_graphql_rules | Enable API and GraphQL service rules (Apollo GraphQL) | `bool` | `false` | no |
| enable_monitoring_analytics_rules | Enable monitoring and analytics rules (Grafana, Rapid7) | `bool` | `false` | no |
| enable_travel_industry_rules | Enable travel industry API rules (Amadeus, Deutsche Bahn, Sabre) | `bool` | `false` | no |
| enable_payment_processing_rules | Enable payment processing rules (Adyen) | `bool` | `false` | no |
| enable_email_services_rules | Enable email service rules (SendGrid) | `bool` | `false` | no |
| enable_crm_rules | Enable CRM service rules (Salesforce) | `bool` | `false` | no |
| enable_cdn_tunneling_rules | Enable CDN and tunneling rules (Cloudflare) | `bool` | `false` | no |
| enable_recruitment_rules | Enable recruitment service rules (Jobylon) | `bool` | `false` | no |
| enable_azure_services_rules | Enable Azure PaaS service rules (Service Bus, App Configuration) | `bool` | `true` | no |
| development_source_addresses | Source addresses for development environment | `list(string)` | `["10.163.0.0/18"]` | no |
| staging_source_addresses | Source addresses for staging environment | `list(string)` | `["10.162.0.0/18"]` | no |
| production_source_addresses | Source addresses for production environment | `list(string)` | `["10.161.0.0/18"]` | no |
| production_vm_subnet_addresses | Source addresses for production VM subnet | `list(string)` | `["10.161.33.0/24"]` | no |

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

## Examples by Use Case

### Development Environment
```hcl
# Minimal rules for development
enable_core_infrastructure_rules = true
enable_source_control_rules      = true
enable_container_registry_rules  = true
enable_package_manager_rules     = true
enable_content_management_rules  = true  # If using Contentful
enable_development_tools_rules   = true  # If using Cypress/Optimizely

# Disable expensive business services
enable_travel_industry_rules    = false
enable_payment_processing_rules = false
enable_crm_rules               = false
```

### Staging Environment
```hcl
# Production-like but with test endpoints
enable_core_infrastructure_rules   = true
enable_source_control_rules        = true
enable_container_registry_rules    = true
enable_package_manager_rules       = true
enable_content_management_rules    = true
enable_authentication_rules        = true
enable_development_tools_rules     = true
enable_api_graphql_rules           = true
enable_monitoring_analytics_rules  = true
enable_travel_industry_rules       = true  # Uses test endpoints
enable_payment_processing_rules    = true  # Uses test endpoints
enable_email_services_rules        = true
enable_crm_rules                   = true  # Uses sandbox
```

### Production Environment
```hcl
# All business services enabled
enable_core_infrastructure_rules   = true
enable_source_control_rules        = true
enable_container_registry_rules    = true
enable_package_manager_rules       = true
enable_content_management_rules    = true
enable_authentication_rules        = true
enable_communication_rules         = true
enable_api_graphql_rules           = true
enable_monitoring_analytics_rules  = true
enable_travel_industry_rules       = true  # Uses production endpoints
enable_payment_processing_rules    = true  # Uses live endpoints
enable_email_services_rules        = true
enable_crm_rules                   = true  # Uses production Salesforce
enable_cdn_tunneling_rules         = true
enable_recruitment_rules           = true
enable_azure_services_rules        = true
``` 