<!-- BEGIN_TF_DOCS -->
# Azure VPN gateway module

This module simplifies the creation of Azure VPN gateway and (optional) one or more local network gateways (connections). It is designed to be flexible, modular, and easy to use, ensuring a seamless Azure VPN gateway deployment.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_local_network_gateway.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/local_network_gateway) | resource |
| [azurerm_public_ip.pip_vgw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.pip_vgw_aa](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_virtual_network_gateway.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway) | resource |
| [azurerm_virtual_network_gateway_connection.vpn](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway_connection) | resource |
| [random_password.vpn_shared_key](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_gateway_subnet"></a> [gateway\_subnet](#input\_gateway\_subnet) | (Required) The gateway subnet for the virtual network gateway (must be set via a module or data source). | <pre>object({<br>    id = string<br>  })</pre> | n/a | yes |
| <a name="input_general"></a> [general](#input\_general) | (Required) General configuration used for naming resources, location etc. | <pre>object({<br>    prefix      = string<br>    application = string<br>    environment = string<br>    location    = string<br>    resource_group = object({<br>      name = string<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_local_network_gateways"></a> [local\_network\_gateways](#input\_local\_network\_gateways) | (Optional) List of local network gateways to connect to the virtual network gateway. | <pre>list(object({<br>    name            = string<br>    gateway_address = string<br>    instance        = optional(string, "001")<br>    address_space   = optional(list(string))<br>    bgp_settings = optional(object({<br>      asn                 = number<br>      bgp_peering_address = string<br>      peer_weight         = optional(number)<br>    }))<br>    connection_protocol = optional(string, "IKEv2")<br>    connection_mode     = optional(string, "Default")<br>    ipsec_policy = optional(object({<br>      dh_group         = string<br>      ike_encryption   = string<br>      ike_integrity    = string<br>      ipsec_encryption = string<br>      ipsec_integrity  = string<br>      pfs_group        = string<br>      sa_datasize      = optional(number)<br>      sa_lifetime      = optional(number)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) The tags that will be applied once during the creation of the resources. | `map(string)` | `{}` | no |
| <a name="input_virtual_network_gateway"></a> [virtual\_network\_gateway](#input\_virtual\_network\_gateway) | (Optional) Change the virtual network gateway configuration. | <pre>object({<br>    instance      = optional(string, "001")<br>    sku           = optional(string, "VpnGw1")<br>    active_active = optional(bool, false)<br>    generation    = optional(string, "Generation1")<br>    enable_bgp    = optional(bool, false)<br>    bgp_settings = optional(object({<br>      asn                   = optional(string, "65515")<br>      peer_weight           = optional(number)<br>      ip_configuration_name = optional(string)<br>      apipa_addresses       = optional(list(string), [])<br>    }))<br>    custom_route = optional(object({<br>      address_prefixes = list(string)<br>    }))<br>  })</pre> | `{}` | no |
| <a name="input_vpn_client_configuration"></a> [vpn\_client\_configuration](#input\_vpn\_client\_configuration) | (Optional) Enable and configure the point-to-site VPN on the virtual network gateway. | <pre>object({<br>    address_space        = list(string)<br>    aad_tenant           = optional(string)<br>    aad_audience         = optional(string)<br>    vpn_client_protocols = optional(list(string), ["OpenVPN"])<br>    vpn_auth_types       = optional(list(string), ["AAD"])<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vpn_gateway_id"></a> [vpn\_gateway\_id](#output\_vpn\_gateway\_id) | The resource ID of the virtual network gateway. |
| <a name="output_vpn_gateway_public_ip"></a> [vpn\_gateway\_public\_ip](#output\_vpn\_gateway\_public\_ip) | The public IP(s) of the virtual network gateway. |

## Example(s)

### Azure VPN gateway with default options and 1 local network gateway (connection)

```hcl
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
}
```

 ### Azure VPN gateway with default options, 1 local network gateway (connection) and user (point-to-site) VPN

```hcl
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
```

# Known issues and limitations

- The shared keys for the VPN connections must be obtained from within the terraform state file.

# Author

Stefan Vonk (vonk.stefan@live.nl) Technical Specialist
<!-- END_TF_DOCS -->