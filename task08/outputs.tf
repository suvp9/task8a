output "aci_fqdn" {
  value       = module.aci.aci_fqdn
  description = "sku"
}

output "aks_lb_ip" {
  value       = data.kubernetes_service.k8_service.status[0].load_balancer[0].ingress[0].ip
  description = "value"
}