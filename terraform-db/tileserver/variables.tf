variable "location" {
  type    = string
  default = "canada central"
}

variable "rg_name" {
  type    = string
  default = "tileserver-rg"
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
  default = "pg_tileserv"
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "registry_name" {
  type    = string
  default = "pramsey"
}