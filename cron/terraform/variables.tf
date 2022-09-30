variable "acr_username" {
    type = string
    sensitive = true
}

variable "acr_password" {
    type = string
    sensitive = true
}

variable "url" {
    type = string
    sensitive = true
}

variable "psql_host" {
  type = string
  sensitive = true
}

variable "psql_db" {
  type = string
  sensitive = true
}

variable "psql_user" {
  type = string
  sensitive = true
}

variable "psql_password" {
  type = string
  sensitive = true
}

variable "psql_port" {
  type = string
  sensitive = true
}
