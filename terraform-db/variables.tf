variable "location" {
  type    = string
  default = "canada central"
}

variable "rg_name" {
  type    = string
  default = "db-rg"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "admin_username" {
  type      = string
  sensitive = true
}

variable "db_storage_mb" {
  type      = string
  default   = 5120
}
