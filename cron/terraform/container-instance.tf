resource "azurerm_container_group" "cron_container" {
  name                = "cron_container"
  location            = azurerm_resource_group.cron_rg.location
  resource_group_name = azurerm_resource_group.cron_rg.name
  ip_address_type     = "Public"
  dns_name_label      = "aci-label"
  os_type             = "Linux"
  restart_policy      = "Never"

  container {
    name   = "data_transformer"
    image  = "foundrymainregistry.azurecr.io/pytest:latest"
    cpu    = "0.5"
    memory = "1.5"

    secure_environment_variables = {
        url=var.url
        POSTGRES_HOST=var.psql_host
        POSTGRES_DB=var.psql_db
        POSTGRES_USER=var.psql_user
        POSTGRES_PASSWORD=var.psql_password
        POSTGRES_PORT=var.psql_port
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

  tags = {
    environment = "testing"
  }
}