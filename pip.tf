# public ip for virtual network gateway
resource "azurerm_public_ip" "pip_vgw" {
  name                = lower("${var.general.prefix}-pip-vpng-${var.general.application}-${local.suffix}-${var.virtual_network_gateway.instance}")
  location            = var.general.location
  resource_group_name = var.general.resource_group.name
  tags                = var.tags
  allocation_method   = "Static"
  sku                 = "Standard"

  lifecycle {
    ignore_changes = [tags]
  }
}

# active_active public ip for virtual network gateway
resource "azurerm_public_ip" "pip_vgw_aa" {
  count = var.virtual_network_gateway.active_active ? 1 : 0

  name                = lower("${var.general.prefix}-pip-aa-vpng-${var.general.application}-${local.suffix}-${var.virtual_network_gateway.instance}")
  location            = var.general.location
  resource_group_name = var.general.resource_group.name
  tags                = var.tags
  allocation_method   = "Static"
  sku                 = "Standard"

  lifecycle {
    ignore_changes = [tags]
  }
}
