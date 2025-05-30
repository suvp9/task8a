resource "azurerm_container_group" "container_group" {
  name                = var.container_group_name
  resource_group_name = var.rg_name
  location            = var.location
  os_type             = var.os_type
  ip_address_type     = "Public"
  dns_name_label      = var.container_group_name

  image_registry_credential {
    server   = var.acr_login_server
    username = var.acr_admin_username
    password = var.acr_admin_password
  }

  container {
    name   = var.container_name
    image  = var.container_image
    cpu    = var.container_cpu
    memory = var.container_memory

    cpu_limit    = var.container_cpu
    memory_limit = var.container_memory

    ports {
      port     = 8080
      protocol = "TCP"
    }
    environment_variables        = var.container_environment_variables
    secure_environment_variables = var.container_secure_environment_variables
  }

  tags = var.tags
}