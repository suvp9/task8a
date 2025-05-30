locals {
  rg_name = format("%s-rg", var.name_prefix)

  acr_name = lower(replace(format("%scr", var.name_prefix), "-", ""))

  app_image_name = format("%s-app", var.name_prefix)

  aci_name = format("%s-ci", var.name_prefix)

  aks_name = format("%s-aks", var.name_prefix)

  redis_name = format("%s-redis", var.name_prefix)

  keyvault_name = format("%s-kv", var.name_prefix)

  redis_hostname_secret_name    = "redis-hostname"
  redis_primary_key_secret_name = "redis-primary-key"

  tags = {
    Creator = ""
  }
  dns_name_label = "mydnslabel"
  dns_prefix     = "${var.name_prefix}-k8s"
}