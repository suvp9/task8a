output "aks_kube_config" {
  value     = azurerm_kubernetes_cluster.k8_cluster.kube_config_raw
  sensitive = true
}

output "aks_kv_access_identity_id" {
  value = azurerm_kubernetes_cluster.k8_cluster.kubelet_identity[0].client_id
}