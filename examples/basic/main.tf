terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.use_oidc ? null : var.client_secret
  tenant_id       = var.tenant_id
  use_oidc        = var.use_oidc
}

# Create a resource group for the example
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Use the firewall module
module "firewall" {
  source = "../.."

  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  # Hub Virtual Network configuration
  hub_vnet_config = {
    vnet_name              = "${var.project_name}-${var.environment}-hub-vnet"
    address_space          = ["10.0.0.0/16"]
    firewall_subnet_cidr   = "10.0.1.0/26"
    management_subnet_cidr = "10.0.2.0/26"
    create_vnet            = true
  }

  # Basic firewall configuration
  firewall_config = {
    name              = "${var.project_name}-${var.environment}-firewall"
    sku_tier          = var.firewall_sku_tier
    # threat_intel_mode defaults to "Deny" for security compliance
    public_ip_count   = 1
    zones             = [] # No zones for simplicity
    forced_tunneling  = false
    dns_servers       = []
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
} 