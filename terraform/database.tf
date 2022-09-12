resource "azurerm_postgresql_server" "psql_server" {
  name                = "pineapple-psql-server"
  location            = azurerm_resource_group.db_rg.location
  resource_group_name = azurerm_resource_group.db_rg.name

  sku_name = "GP_Gen5_2"

  storage_mb                   = var.db_storage_mb
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = false

  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password
  version                      = "9.5"
  ssl_enforcement_enabled      = true
}

resource "azurerm_postgresql_database" "psql_db" {
  name                = "psqldb"
  resource_group_name = azurerm_resource_group.db_rg.name
  server_name         = azurerm_postgresql_server.psql_server.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}