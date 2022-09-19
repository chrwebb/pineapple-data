resource "azurerm_postgresql_flexible_server" "psql_server" {
  name                = "pineapple-psql-server"
  location            = azurerm_resource_group.db_rg.location
  resource_group_name = azurerm_resource_group.db_rg.name

  sku_name = "GP_Standard_D4s_v3"

  storage_mb                   = var.db_storage_mb
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  administrator_login          = var.psql_user
  administrator_password = var.psql_password
  version                      = "13"
  zone                   = "1"
}

resource "azurerm_postgresql_flexible_server_database" "psql_db" {
  name      = var.psql_db
  server_id = azurerm_postgresql_flexible_server.psql_server.id
  collation = "en_US.UTF8"
  charset   = "UTF8"
}
