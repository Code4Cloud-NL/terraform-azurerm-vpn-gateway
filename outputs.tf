output "vpn_gateway_id" {
  description = "The resource ID of the virtual network gateway."
  value       = azurerm_virtual_network_gateway.this.id
}

output "vpn_gateway_public_ip" {
  description = "The public IP(s) of the virtual network gateway."
  value       = flatten(concat([azurerm_public_ip.pip_vgw.ip_address], [var.virtual_network_gateway.active_active != null ? azurerm_public_ip.pip_vgw_aa[*].ip_address : null]))
}
