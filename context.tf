locals {
  location_table = {
    westeurope  = "westeu"
    northeurope = "northeu"
  }

  suffix = "${var.general.environment}-${local.location_table[var.general.location]}"
}
