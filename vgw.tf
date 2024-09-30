# virtual network gateway
resource "azurerm_virtual_network_gateway" "this" {
  name                = lower("${var.general.prefix}-vpng-${var.general.application}-${local.suffix}-${var.virtual_network_gateway.instance}")
  location            = var.general.location
  resource_group_name = var.general.resource_group.name
  tags                = var.tags
  type                = "Vpn"
  sku                 = var.virtual_network_gateway.sku
  active_active       = var.virtual_network_gateway.active_active
  generation          = var.virtual_network_gateway.generation
  enable_bgp          = var.virtual_network_gateway.enable_bgp

  dynamic "bgp_settings" {
    for_each = var.virtual_network_gateway.enable_bgp ? [true] : []
    content {
      asn = var.virtual_network_gateway.bgp_settings.asn
      peering_addresses {
        ip_configuration_name = var.virtual_network_gateway.bgp_settings.ip_configuration_name
        apipa_addresses       = var.virtual_network_gateway.bgp_settings.apipa_addresses
      }
      peer_weight = var.virtual_network_gateway.bgp_settings.peer_weight
    }
  }

  dynamic "custom_route" {
    for_each = var.virtual_network_gateway.custom_route[*]
    content {
      address_prefixes = custom_route.value.address_prefixes
    }
  }

  ip_configuration {
    name                          = "vnetGatewayConfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet.id
    public_ip_address_id          = azurerm_public_ip.pip_vgw.id
  }

  dynamic "ip_configuration" {
    for_each = var.virtual_network_gateway.active_active ? [true] : []
    content {
      name                          = "vnetGatewayAAConfig"
      private_ip_address_allocation = "Dynamic"
      subnet_id                     = var.gateway_subnet.id
      public_ip_address_id          = azurerm_public_ip.pip_vgw_aa.id
    }
  }

  dynamic "vpn_client_configuration" {
    for_each = var.vpn_client_configuration[*]
    content {
      address_space        = var.vpn_client_configuration.address_space
      aad_tenant           = "https://login.microsoftonline.com/${var.vpn_client_configuration.aad_tenant}"
      aad_audience         = var.vpn_client_configuration.aad_audience
      aad_issuer           = "https://sts.windows.net/${var.vpn_client_configuration.aad_tenant}/"
      vpn_client_protocols = var.vpn_client_configuration.vpn_client_protocols
      vpn_auth_types       = var.vpn_client_configuration.vpn_auth_types
    }
  }

  lifecycle {
    ignore_changes = [tags]
  }
}
