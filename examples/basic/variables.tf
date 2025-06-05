variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-firewall-example"
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "swedencentral"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "firewall"
}

variable "firewall_sku_name" {
  description = "SKU name of the Azure Firewall"
  type        = string
  default     = "AZFW_VNet"
}

variable "firewall_sku_tier" {
  description = "SKU tier of the Azure Firewall"
  type        = string
  default     = "Standard"
}

variable "enable_network_rules" {
  description = "Whether to enable network rules on the firewall"
  type        = bool
  default     = false
}

variable "enable_application_rules" {
  description = "Whether to enable application rules on the firewall"
  type        = bool
  default     = false
} 