resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_az_services" {
  name             = "psql-fwrule-allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.psql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}