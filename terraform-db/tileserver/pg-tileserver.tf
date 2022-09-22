data "azurerm_postgresql_flexible_server" "psql_server" {
  name                = "pineapple-psql-server"
  resource_group_name = "db-rg"
}

resource "azurerm_container_group" "pg_tileserver" {
  name                = "pg-tileserver"
  location            = azurerm_resource_group.pg_tileserver_rg.location
  resource_group_name = azurerm_resource_group.pg_tileserver_rg.name
  ip_address_type     = "Public"
  dns_name_label      = "pg-tileserver-cg"
  os_type             = "Linux"
  restart_policy      = "Never"

  container {
    name   = "pg-tileserver"
    image  = "${var.registry_name}/${var.image_name}:${var.image_tag}"
    cpu    = "0.5"
    memory = "1"

    secure_environment_variables = {
      DATABASE_URL = "postgresql://${var.psql_user}:${var.psql_password}@${data.azurerm_postgresql_flexible_server.psql_server.fqdn}:${var.psql_port}/${var.psql_db}"
    }

    environment_variables = {
      TS_CORSORIGINS="\"*\""
    }

    ports {
      port     = 7800
      protocol = "TCP"
    }
  }

  container {
    name   = "caddy"
    image  = "caddy"
    cpu    = "0.5"
    memory = "0.5"

    ports {
      port     = 443
      protocol = "TCP"
    }

    ports {
      port     = 80
      protocol = "TCP"
    }

    volume {
      name                 = "aci-caddy-data"
      mount_path           = "/data"
      storage_account_name = azurerm_storage_account.aci_caddy.name
      storage_account_key  = azurerm_storage_account.aci_caddy.primary_access_key
      share_name           = azurerm_storage_share.aci_caddy.name
    }

    volume {
      name                 = "aci-caddy-file"
      mount_path           = "/etc/caddy"
      storage_account_name = azurerm_storage_account.aci_caddy.name
      storage_account_key  = azurerm_storage_account.aci_caddy.primary_access_key
      share_name           = azurerm_storage_share.aci_caddy_file.name
    }
  }
}
