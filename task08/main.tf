provider "azurerm" {
  features {}
}

data "azurerm_client_config" "client_config" {}

resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location

  tags = local.tags
}

module "acr" {
  source = "./modules/acr"

  rg_name       = azurerm_resource_group.rg.name
  location      = azurerm_resource_group.rg.location
  acr_name      = local.acr_name
  acr_task_name = var.acr_task_name
  acr_sku       = var.acr_sku
  platform_os   = var.platform_os

  dockerfile_path           = var.dockerfile_path
  docker_build_context_path = var.docker_build_context_path
  context_access_token      = var.context_access_token
  docker_image_name         = local.app_image_name

  tags = local.tags
}


module "kv" {
  source   = "./modules/keyvault"
  kv_name  = local.keyvault_name
  rg_name  = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  sku_name = var.kv_sku_name

  tenant_id = data.azurerm_client_config.client_config.tenant_id
  object_id = data.azurerm_client_config.client_config.object_id

  tags       = local.tags
  depends_on = [module.acr]
}

module "redis" {
  source = "./modules/redis"

  rg_name          = azurerm_resource_group.rg.name
  redis_cache_name = local.redis_name
  location         = azurerm_resource_group.rg.location
  family           = var.redis_family
  sku_name         = var.redis_sku_name
  capacity         = var.redis_capacity

  key_vault_id                            = module.kv.kv_id
  key_vault_secret_redis_hostname_name    = local.redis_hostname_secret_name
  key_vault_secret_redis_primary_key_name = local.redis_primary_key_secret_name

  tags = local.tags

  depends_on = [module.kv]
}

data "azurerm_key_vault_secret" "redis_url" {
  name         = local.redis_hostname_secret_name
  key_vault_id = module.kv.kv_id

  depends_on = [module.redis]
}

data "azurerm_key_vault_secret" "redis_pwd" {
  name         = local.redis_primary_key_secret_name
  key_vault_id = module.kv.kv_id

  depends_on = [module.redis]
}

module "aci" {
  source = "./modules/aci"

  container_group_name = local.aci_name
  rg_name              = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  os_type              = var.aci_os_type

  container_name   = var.aci_container_name
  container_cpu    = var.aci_container_cpu
  container_memory = var.aci_container_memory

  acr_login_server   = module.acr.login_server
  acr_admin_username = module.acr.admin_username
  acr_admin_password = module.acr.admin_password

  container_image                 = "${module.acr.login_server}/${var.docker_image_name}:latest"
  container_environment_variables = var.aci_container_environment_variables
  container_secure_environment_variables = {
    "REDIS_URL" = data.azurerm_key_vault_secret.redis_url.value,
    "REDIS_PWD" = data.azurerm_key_vault_secret.redis_pwd.value,
  }
  tags = local.tags

  depends_on = [module.acr, module.kv, module.redis]
}

module "aks" {
  source = "./modules/aks"

  aks_cluster_name = local.aks_name
  rg_name          = azurerm_resource_group.rg.name
  location         = azurerm_resource_group.rg.location
  dns_prefix       = local.dns_prefix

  system_node_pool_name       = var.system_node_pool_name
  system_node_pool_node_count = var.system_node_pool_node_count
  system_node_pool_vm_size    = var.system_node_pool_vm_size

  acr_id       = module.acr.acr_id
  tenant_id    = data.azurerm_client_config.client_config.tenant_id
  key_vault_id = module.kv.kv_id

  tags       = local.tags
  depends_on = [module.acr, module.kv, module.redis, module.aci]
}

provider "kubectl" {
  host                   = yamldecode(module.aks.aks_kube_config).clusters[0].cluster.server
  client_certificate     = base64decode(yamldecode(module.aks.aks_kube_config).users[0].user.client-certificate-data)
  client_key             = base64decode(yamldecode(module.aks.aks_kube_config).users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(yamldecode(module.aks.aks_kube_config).clusters[0].cluster.certificate-authority-data)
  load_config_file       = false
}

provider "kubernetes" {
  host                   = yamldecode(module.aks.aks_kube_config).clusters[0].cluster.server
  client_certificate     = base64decode(yamldecode(module.aks.aks_kube_config).users[0].user.client-certificate-data)
  client_key             = base64decode(yamldecode(module.aks.aks_kube_config).users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(yamldecode(module.aks.aks_kube_config).clusters[0].cluster.certificate-authority-data)
}
resource "kubectl_manifest" "secret_provider" {
  yaml_body = templatefile("${path.module}/k8s-manifests/secret-provider.yaml.tftpl", {
    aks_kv_access_identity_id  = module.aks.aks_kv_access_identity_id
    kv_name                    = local.keyvault_name
    redis_url_secret_name      = var.redis_hostname_secret_name
    redis_password_secret_name = var.redis_primary_key_secret_name
    tenant_id                  = data.azurerm_client_config.client_config.tenant_id
  })

  depends_on = [module.aks, module.redis, module.kv]
}

resource "kubectl_manifest" "deployment" {
  yaml_body = templatefile("${path.module}/k8s-manifests/deployment.yaml.tftpl", {
    acr_login_server = "${local.acr_name}.azurecr.io"
    app_image_name   = var.docker_image_name
    image_tag        = "latest"
  })

  wait_for {
    field {
      key   = "status.availableReplicas"
      value = "1"
    }
  }
  depends_on = [module.aks, kubectl_manifest.secret_provider]
}

resource "kubectl_manifest" "service" {
  wait_for {
    field {
      key        = "status.loadBalancer.ingress.[0].ip"
      value      = "^(\\d+(\\.|$)){4}"
      value_type = "regex"
    }
  }

  yaml_body = file("${path.module}/k8s-manifests/service.yaml")

  depends_on = [module.aks, kubectl_manifest.deployment]
}

data "kubernetes_service" "k8_service" {
  metadata {
    name = "redis-flask-app-service"
  }
  depends_on = [kubectl_manifest.service]
}