module "vpn_gateway" {
  source = "../modules/terraform-azurerm-vpn-gateway"

  general = {                                                 # (required) general information used in the naming of resources etc.
    prefix         = "c4c"                                    # (required) the prefix of the customer (e.g. c4c)
    application    = "connectivity"                           # (required) the unique name of the vpn gateway (must be unique within the subscription)
    environment    = "prd"                                    # (required) the environment (e.g. lab, stg, dev, tst, acc, prd)
    location       = "westeurope"                             # (required) the location for the resources (e.g. westeurope, northeurope)
    resource_group = data.azurerm_resource_group.example.name # (required) the resource group for the resources (must be set via a module or data source)
  }

  tags = { # (optional) a map of tags applied to the resources
    environment = "prd"
    location    = "westeurope"
    managed_by  = "terraform"
  }

  gateway_subnet = data.azurerm_subnet.example.id # (required) the gateway subnet for the virtual network gateway (must be set via a module or data source)

  local_network_gateways = [ # (optional) list of local network gateways / site-to-site vpn connections for the virtual network gateway
    {
      name            = "datacenter"                    # (required) the unique name of the site-to-site vpn connection (must be unique within the module)
      gateway_address = "8.8.8.8"                       # (required) the gateway address for the local network gateway (e.g. the IP of the on-premise vpn device)
      address_space   = ["10.0.0.0/8", "172.16.0.0/12"] # (required) list of address space(s) for the local network gateway (e.g. the IP ranges of the on-premise networks)
    }
  ]

  vpn_client_configuration = {                             # (optional) enable and configure the point-to-site vpn on the virtual network gateway
    address_space = ["10.15.0.0/16"]                       # (required) the address space for the vpn clients
    aad_tenant    = "00000000-0000-0000-0000-000000000000" # (required) the tenant id of the azure ad tenant
    aad_audience  = "00000000-0000-0000-0000-000000000000" # (required) the application id of the azure vpn enterprise application (this needs to be created first)
  }
}
