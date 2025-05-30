resource "azurerm_redis_cache" "redis_cache" {
  name                = var.redis_cache_name
  resource_group_name = var.rg_name
  location            = var.location
  sku_name            = var.sku_name
  capacity            = var.capacity
  family              = var.family

  tags = var.tags
}

resource "azurerm_key_vault_secret" "key_vault_secret_hostname" {
  name         = var.key_vault_secret_redis_hostname_name
  value        = azurerm_redis_cache.redis_cache.hostname
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_redis_cache.redis_cache]
}

resource "azurerm_key_vault_secret" "key_vault_secret_primary_key" {
  name         = var.key_vault_secret_redis_primary_key_name
  value        = azurerm_redis_cache.redis_cache.primary_access_key
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_redis_cache.redis_cache]
}