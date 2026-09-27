resource "azurerm_resource_group" "resource_group" {
  name     = "rg-cyber-sre-${var.environment}"
  location = var.location

  tags = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-cyber-sre-${var.environment}"
  address_space       = var.address_prefixes
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_subnet" "platform" {
  name                 = "snet-platform"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = [
    var.subnet_address_prefixes[0]
  ]
}

resource "azurerm_subnet" "data" {
  name                 = "snet-data"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = [
    var.subnet_address_prefixes[1]
  ]
}

resource "azurerm_network_security_group" "platform_nsg" {
  name                = "nsg-platform-${var.environment}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_subnet_network_security_group_association" "platform" {
  subnet_id                 = azurerm_subnet.platform.id
  network_security_group_id = azurerm_network_security_group.platform_nsg.id
}

resource "azurerm_storage_account" "data" {
  name                = "stcybersre${var.unique_suffix}"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  is_hns_enabled  = true
  min_tls_version = "TLS1_2"
}

resource "azurerm_storage_data_lake_gen2_filesystem" "raw" {
  name               = "raw"
  storage_account_id = azurerm_storage_account.data.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "processed" {
  name               = "processed"
  storage_account_id = azurerm_storage_account.data.id
}

resource "azurerm_data_factory" "data_factory" {
  name                = "adf-cyber-sre-${var.unique_suffix}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "adf_storage" {
  scope                = azurerm_storage_account.data.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.data_factory.identity[0].principal_id
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "key_vault" {
  name                = "kv-cybersre-${var.unique_suffix}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name  = "standard"

  rbac_authorization_enabled = true

  soft_delete_retention_days = 7

  purge_protection_enabled = false
}

resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "law-cyber-sre-${var.environment}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  sku               = "PerGB2018"
  retention_in_days = 30
}
