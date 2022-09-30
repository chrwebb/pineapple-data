resource "azurerm_storage_account" "aci_caddy" {
  name                      = "acicaddypineapple"
  resource_group_name       = azurerm_resource_group.pg_tileserver_rg.name
  location                  = azurerm_resource_group.pg_tileserver_rg.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
}

resource "azurerm_storage_share" "aci_caddy" {
  name                 = "aci-caddy-data"
  quota                = 1
  storage_account_name = azurerm_storage_account.aci_caddy.name
}

resource "azurerm_storage_share" "aci_caddy_file" {
  name                 = "aci-caddy-file"
  quota                = 1
  storage_account_name = azurerm_storage_account.aci_caddy.name
}

resource "azurerm_storage_share_file" "caddyfile" {
  name             = "Caddyfile"
  storage_share_id = azurerm_storage_share.aci_caddy_file.id
  source           = "Caddyfile"
}