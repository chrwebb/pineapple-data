resource "azurerm_postgresql_firewall_rule" "allow_az_services" {
  name                = "psql-fwrule-allow-azure-services"
  resource_group_name = var.rg_name
  server_name         = azurerm_postgresql_server.psql_server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}