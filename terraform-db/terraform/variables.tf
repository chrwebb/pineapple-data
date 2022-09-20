variable "location" {
  type    = string
  default = "canada central"
}

variable "rg_name" {
  type    = string
  default = "db-rg"
}

variable "db_storage_mb" {
  type    = string
  default = 32768
}

variable "acr_username" {
  type      = string
  sensitive = true
}

variable "acr_password" {
  type      = string
  sensitive = true
}

variable "psql_db" {
  type      = string
  sensitive = true
}

variable "psql_user" {
  type      = string
  sensitive = true
}

variable "psql_password" {
  type      = string
  sensitive = true
}

variable "psql_port" {
  type      = string
  sensitive = true
}

variable "image_name" {
  type    = string
  default = "pineapple_seeds"
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "registry_name" {
  type    = string
  default = "foundrymainregistry.azurecr.io"
}

variable "pg_tileserver_password" {
  type      = string
  sensitive = true
}