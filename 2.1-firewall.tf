resource "azurerm_firewall_policy" "digital_hub" {
  name                = "digital-products-vwan-fw-policy"
  resource_group_name = var.resource_group_name
  location            = var.location
  dns {
    servers       = [var.dns_resolver_private_ip]
    proxy_enabled = true
  }
  tags = var.tags
  lifecycle { ignore_changes = [tags["created_on"]] }
}

resource "azurerm_firewall" "digital_hub" {
  name                = "${var.location}-vhub-fw"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_Hub"
  sku_tier            = var.sku_tier
  virtual_hub {
    virtual_hub_id  = var.virtual_hub_id
    public_ip_count = 1
  }
  firewall_policy_id = azurerm_firewall_policy.digital_hub.id
  tags               = var.tags
  lifecycle { ignore_changes = [tags["created_on"]] }
}

