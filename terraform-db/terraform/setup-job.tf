data "azurerm_postgresql_flexible_server" "psql_server" {
  name                = azurerm_postgresql_flexible_server.psql_server.name
  resource_group_name = azurerm_postgresql_flexible_server.psql_server.resource_group_name
}

resource "azurerm_container_group" "init_db" {
  name                = "init-db"
  location            = azurerm_resource_group.db_rg.location
  resource_group_name = azurerm_resource_group.db_rg.name
  ip_address_type     = "Public"
  dns_name_label      = "init-db-cg"
  os_type             = "Linux"
  restart_policy      = "Never"

  container {
    name   = "init-db"
    image  = "${var.registry_name}/${var.image_name}pineapple_seeds:${var.image_tag}"
    cpu    = "0.5"
    memory = "1"

    environment_variables = {
        PGHOST=data.azurerm_postgresql_flexible_server.psql_server.fqdn
        PGDATABASE=var.psql_db
        PGUSER=var.psql_user
        PGPASSWORD=var.psql_password
        PGPORT=var.psql_port
    }

    ports {
      port     = 443
      protocol = "TCP"
    }
  }

  image_registry_credential {
    username = var.acr_username
    password = var.acr_password
    server = "foundrymainregistry.azurecr.io"
  }
}
