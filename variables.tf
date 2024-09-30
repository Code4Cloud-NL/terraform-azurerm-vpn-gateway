variable "general" {
  description = "(Required) General configuration used for naming resources, location etc."
  type = object({
    prefix      = string
    application = string
    environment = string
    location    = string
    resource_group = object({
      name = string
    })
  })
  validation {
    condition     = contains(["lab", "stg", "dev", "tst", "acc", "prd"], var.general.environment)
    error_message = "Invalid environment specified!"
  }
  validation {
    condition     = contains(["northeurope", "westeurope"], var.general.location)
    error_message = "Invalid location specified!"
  }
}

variable "tags" {
  description = "(Optional) The tags that will be applied once during the creation of the resources."
  type        = map(string)
  default     = {}
}

variable "gateway_subnet" {
  description = "(Required) The gateway subnet for the virtual network gateway (must be set via a module or data source)."
  type = object({
    id = string
  })
}

variable "virtual_network_gateway" {
  description = "(Optional) Change the virtual network gateway configuration."
  type = object({
    instance      = optional(string, "001")
    sku           = optional(string, "VpnGw1")
    active_active = optional(bool, false)
    generation    = optional(string, "Generation1")
    enable_bgp    = optional(bool, false)
    bgp_settings = optional(object({
      asn                   = optional(string, "65515")
      peer_weight           = optional(number)
      ip_configuration_name = optional(string)
      apipa_addresses       = optional(list(string), [])
    }))
    custom_route = optional(object({
      address_prefixes = list(string)
    }))
  })
  default = {}

  validation {
    condition     = length(var.virtual_network_gateway.instance) <= 3
    error_message = "Instance must not exceed 3 characters."
  }
  validation {
    condition     = contains(["VpnGw1", "VpnGw2", "VpnGw3", "VpnGw4", "VpnGw5", "VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ", "VpnGw4AZ", "VpnGw5AZ"], var.virtual_network_gateway.sku)
    error_message = "Invalid sku specified. Possible values are: VpnGw1, VpnGw2, VpnGw3, VpnGw4,VpnGw5, VpnGw1AZ, VpnGw2AZ, VpnGw3AZ,VpnGw4AZ and VpnGw5AZ."
  }
  validation {
    condition     = contains(["Generation1", "Generation2"], var.virtual_network_gateway.generation)
    error_message = "Invalid sku specified. Possible values are: Generation1 and Generation2."
  }
}

variable "vpn_client_configuration" {
  description = "(Optional) Enable and configure the point-to-site VPN on the virtual network gateway."
  type = object({
    address_space        = list(string)
    aad_tenant           = optional(string)
    aad_audience         = optional(string)
    vpn_client_protocols = optional(list(string), ["OpenVPN"])
    vpn_auth_types       = optional(list(string), ["AAD"])
  })
  default = null

  validation {
    condition = var.vpn_client_configuration == null ? true : (
      alltrue([
        for protocol in var.vpn_client_configuration.vpn_client_protocols :
      contains(["OpenVPN", "SSTP", "IKEv2"], protocol)])
    )
    error_message = "Invalid vpn client protocols. Possible values are: SSTP, IkeV2, OpenVPN."
  }
  validation {
    condition = var.vpn_client_configuration == null ? true : (
      alltrue([
        for auth_type in var.vpn_client_configuration.vpn_auth_types :
      contains(["AAD", "Radius", "Certificate"], auth_type)])
    )
    error_message = "Invalid vpn auth type. Possible values are: AAD, Radius, Certificate."
  }
}

variable "local_network_gateways" {
  description = "(Optional) List of local network gateways to connect to the virtual network gateway."
  type = list(object({
    name            = string
    gateway_address = string
    instance        = optional(string, "001")
    address_space   = optional(list(string))
    bgp_settings = optional(object({
      asn                 = number
      bgp_peering_address = string
      peer_weight         = optional(number)
    }))
    connection_protocol = optional(string, "IKEv2")
    connection_mode     = optional(string, "Default")
    ipsec_policy = optional(object({
      dh_group         = string
      ike_encryption   = string
      ike_integrity    = string
      ipsec_encryption = string
      ipsec_integrity  = string
      pfs_group        = string
      sa_datasize      = optional(number)
      sa_lifetime      = optional(number)
    }))
  }))
  default = []

  validation {
    condition = alltrue([
      for lgw in var.local_network_gateways :
      length(lgw.instance) <= 3
    ])
    error_message = "Instance must not exceed 3 characters."
  }

  validation {
    condition = alltrue([
      for lgw in var.local_network_gateways :
      contains(["IKEv2", "IKEv1"], lgw.connection_protocol)
    ])
    error_message = "Invalid connection protocol. Possible values are: IKEv2, IKEv1."
  }
  validation {
    condition = alltrue([
      for lgw in var.local_network_gateways :
      contains(["Default", "InitiatorOnly", "ResponderOnly"], lgw.connection_mode)
    ])
    error_message = "Invalid connection mode. Possible values are: Default, InitiatorOnly and ResponderOnly."
  }
  validation {
    condition = alltrue([
      for lgw in var.local_network_gateways : lgw.ipsec_policy == null ? true : (
        contains(["DHGroup1", "DHGroup14", "DHGroup2", "DHGroup2048", "DHGroup24", "ECP256", "ECP384", "None"], lgw.ipsec_policy.dh_group) &&
        contains(["AES128", "AES192", "AES256", "DES", "DES3", "GCMAES128", "GCMAES256"], lgw.ipsec_policy.ike_encryption) &&
        contains(["GCMAES128", "GCMAES256", "MD5", "SHA1", "SHA256", "SHA384"], lgw.ipsec_policy.ike_integrity) &&
        contains(["AES128", "AES192", "AES256", "DES", "DES3", "GCMAES128", "GCMAES192", "GCMAES256", "None"], lgw.ipsec_policy.ipsec_encryption) &&
        contains(["GCMAES128", "GCMAES192", "GCMAES256", "MD5", "SHA1", "SHA256"], lgw.ipsec_policy.ipsec_integrity) &&
        contains(["ECP256", "ECP384", "PFS1", "PFS14", "PFS2", "PFS2048", "PFS24", "PFSMM", "None"], lgw.ipsec_policy.pfs_group)
      )
    ])
    error_message = <<EOH
    Ipsec_policy contains errors. Possible values are: 
    
    dh_group: DHGroup1, DHGroup14, DHGroup2, DHGroup2048, DHGroup24, ECP256, ECP384, or None.
    ike_encryption: AES128, AES192, AES256, DES, DES3, GCMAES128, or GCMAES256.
    ike_integrity: GCMAES128, GCMAES256, MD5, SHA1, SHA256, or SHA384.
    ipsec_encryption: AES128, AES192, AES256, DES, DES3, GCMAES128, GCMAES192, GCMAES256, or None.
    ipsec_integrity: GCMAES128, GCMAES192, GCMAES256, MD5, SHA1, or SHA256.
    pfs_group: ECP256, ECP384, PFS1, PFS14, PFS2, PFS2048, PFS24, PFSMM, or None.

    EOH
  }
}
