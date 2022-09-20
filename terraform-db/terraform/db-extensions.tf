# See https://github.com/hashicorp/terraform-provider-azurerm/pull/17580/files for docs on adding extensions

resource "azurerm_postgresql_flexible_server_configuration" "postgis" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.psql_server.id
  value     = "POSTGIS,UUID-OSSP,POSTGIS_RASTER"
}