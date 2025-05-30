variable "redis_cache_name" {
  type        = string
  description = "sku"
}
variable "rg_name" {
  type        = string
  description = "sku"
}

variable "location" {
  description = "sku"
  type        = string
}
variable "sku_name" {
  type        = string
  description = "sku"
}
variable "family" {
  type        = string
  description = "sku"
}
variable "capacity" {
  type        = number
  description = "sku"
}

variable "key_vault_secret_redis_primary_key_name" {
  type        = string
  description = "sku"
}

variable "key_vault_secret_redis_hostname_name" {
  type        = string
  description = "sku"
}

variable "key_vault_id" {
  type        = string
  description = "sku"
}

variable "tags" {
  type        = map(string)
  description = "sku"
}