terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7"
    }
  }
}

provider "azurerm" {
  features {}
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

# Create a Virtual WAN
resource "azurerm_virtual_wan" "example" {
  name                = "${var.project_name}-${var.environment}-vwan"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create a Virtual Hub
resource "azurerm_virtual_hub" "example" {
  name                = "${var.project_name}-${var.environment}-vhub"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  virtual_wan_id      = azurerm_virtual_wan.example.id
  address_prefix      = "10.0.0.0/24"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create a DNS resolver private IP (mock for example)
resource "azurerm_virtual_network" "dns_resolver" {
  name                = "${var.project_name}-${var.environment}-dns-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "azurerm_subnet" "dns_resolver" {
  name                 = "dns-resolver-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.dns_resolver.name
  address_prefixes     = ["10.1.0.0/24"]
}

# Create GitHub runner network (mock for example)
resource "azurerm_virtual_network" "github_runner" {
  name                = "${var.project_name}-${var.environment}-github-vnet"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Use the firewall module
module "firewall" {
  source = "../.."

  resource_group_name                    = azurerm_resource_group.example.name
  location                              = azurerm_resource_group.example.location
  virtual_hub_id                        = azurerm_virtual_hub.example.id
  dns_resolver_private_ip               = "10.1.0.4" # Example IP from DNS resolver subnet
  github_runner_network_address_space   = ["10.2.0.0/16"]
  github_runner_network_id              = azurerm_virtual_network.github_runner.id
  vpn_network_address_space             = "10.3.0.0/16"
  sku_tier                              = var.firewall_sku_tier

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
} 