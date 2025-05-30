output "aci_ip_address" {
  value = azurerm_container_group.container_group.ip_address
}
output "aci_fqdn" {
  value = azurerm_container_group.container_group.fqdn
}