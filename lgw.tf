# local network gateways
resource "azurerm_local_network_gateway" "this" {
  for_each = { for lgw in var.local_network_gateways : "${lgw.name}-${lgw.instance}" => lgw }

  name                = lower("${var.general.prefix}-lgw-${each.value.name}-${local.suffix}-${each.value.instance}")
  location            = var.general.location
  resource_group_name = var.general.resource_group.name
  tags                = var.tags
  gateway_address     = each.value.gateway_address
  address_space       = each.value.address_space

  dynamic "bgp_settings" {
    for_each = each.value.bgp_settings[*]

    content {
      asn                 = bgp_settings.value.asn
      bgp_peering_address = bgp_settings.value.bgp_peering_address
      peer_weight         = bgp_settings.value.peer_weight
    }
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

# shared keys for vpn connections
resource "random_password" "vpn_shared_key" {
  for_each = { for lgw in var.local_network_gateways : "${lgw.name}-${lgw.instance}" => lgw }

  length           = 25
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "@#%*-_=+"

  lifecycle {
    prevent_destroy = true
  }
}

# virtual network gateway connections for vpn gateway
resource "azurerm_virtual_network_gateway_connection" "vpn" {
  for_each = { for lgw in var.local_network_gateways : "${lgw.name}-${lgw.instance}" => lgw }

  name                       = lower("${var.general.prefix}-con-vpn-${each.value.name}-${local.suffix}-${each.value.instance}")
  location                   = var.general.location
  resource_group_name        = var.general.resource_group.name
  tags                       = var.tags
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this.id
  local_network_gateway_id   = azurerm_local_network_gateway.this[each.key].id
  shared_key                 = random_password.vpn_shared_key[each.key].result
  connection_protocol        = var.virtual_network_gateway.sku == ["VpnGw1", "VpnGw2", "VpnGw3", "VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ"] ? each.value.connection_protocol : null
  connection_mode            = each.value.connection_mode

  dynamic "ipsec_policy" {
    for_each = each.value.ipsec_policy[*]
    content {
      dh_group         = ipsec_policy.value.dh_group
      ike_encryption   = ipsec_policy.value.ike_encryption
      ike_integrity    = ipsec_policy.value.ike_integrity
      ipsec_encryption = ipsec_policy.value.ipsec_encryption
      ipsec_integrity  = ipsec_policy.value.ipsec_integrity
      pfs_group        = ipsec_policy.value.pfs_group
      sa_datasize      = ipsec_policy.value.sa_datasize
      sa_lifetime      = ipsec_policy.value.sa_lifetime
    }
  }

  lifecycle {
    ignore_changes = [tags]
  }
}
