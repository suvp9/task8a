variable "container_group_name" {
  type        = string
  description = "sku"
}

variable "rg_name" {
  type        = string
  description = "sku"
}

variable "location" {
  type        = string
  description = "sku"
}

variable "os_type" {
  type        = string
  description = "sku"
}

variable "container_name" {
  type        = string
  description = "sku"
}

variable "container_image" {
  type        = string
  description = "sku"
}

variable "container_cpu" {
  type        = string
  description = "sku"
}

variable "container_memory" {
  type        = string
  description = "sku"
}

variable "container_environment_variables" {
  type        = map(string)
  description = "sku"
}

variable "container_secure_environment_variables" {
  type        = map(string)
  sensitive   = true
  description = "sku"
}

variable "acr_login_server" {
  type        = string
  description = "sku"
}
variable "acr_admin_password" {
  type        = string
  description = "sku"
}
variable "acr_admin_username" {
  description = "sku"
  type        = string
}
variable "tags" {
  description = "sku"
  type        = map(string)
}