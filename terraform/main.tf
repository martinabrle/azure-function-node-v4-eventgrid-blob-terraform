# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventgrid_event_subscription
# https://github.com/Azure-Samples/azure-functions-event-grid-terraform/blob/main/infrastructure/terraform/main.tf
# https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Root module should specify the maximum provider version
      # The ~> operator is a convenient shorthand for allowing only patch releases within a specific minor release.
      version = "~> 3.55"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.project}-${var.environment}-rg"
  location = var.location
}

resource "azurerm_eventgrid_topic" "eventgrid_topic_blob" {
  name                = "${var.project}${var.environment}-egt"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  identity {
    type = "SystemAssigned"
  }
  tags = {
    DELETE_NIGHTLY = "true"
  }
}

resource "azurerm_storage_account" "function_storage_account" {
  name                     = "${var.project}${var.environment}safunc"
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account" "inbox_storage_account" {
  name                     = "${var.project}${var.environment}sainbox"
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account" "destination_storage_account" {
  name                     = "${var.project}${var.environment}saout"
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "destination_storage_account_share" {
  name                 = var.destination_file_share_name
  storage_account_name = azurerm_storage_account.destination_storage_account.name
  quota                = 5
}
resource "azurerm_application_insights" "application_insights" {
  name                = "${var.project}-${var.environment}-application-insights"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  application_type    = "Node.JS"
}

resource "azurerm_service_plan" "app_service_plan" {
  name                = "${var.project}-${var.environment}-app-service-plan"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "function_app" {
  name                        = "${var.project}-${var.environment}-function-app"
  resource_group_name         = azurerm_resource_group.resource_group.name
  location                    = var.location
  service_plan_id             = azurerm_service_plan.app_service_plan.id
  storage_account_name        = azurerm_storage_account.function_storage_account.name
  storage_account_access_key  = azurerm_storage_account.function_storage_account.primary_access_key
  functions_extension_version = "~4"
  deploy_zip = 
  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"                = azurerm_application_insights.application_insights.instrumentation_key,
    "APPLICATIONINSIGHTS_CONNECTION_STRING"         = azurerm_application_insights.application_insights.connection_string,
    "DESTINATION_STORAGE_ACCOUNT_CONNECTION_STRING" = azurerm_storage_account.destination_storage_account.primary_connection_string,
    "DESTINATION_STORAGE_ACCOUNT_CONNECTION_STRING" = azurerm_storage_share.destination_storage_account_share.name
    "AzureWebJobsFeatureFlags"                      = "EnableWorkerIndexing"
  }
  site_config {
    app_scale_limit          = 1
    elastic_instance_minimum = 0
    application_stack {
      node_version = 18
    }
    # cors {
    #   #CORS NOT NEEDED, IF NEEDED for HTTP TRIGGER, CHANGE THIS:
    #   allowed_origins = ["*"]
    # }
  }

  lifecycle {
    ignore_changes = [
      app_settings["AzureWebJobsDashboard"],
      app_settings["AzureWebJobsStorage"],
      app_settings["WEBSITE_CONTENTAZUREFILECONNECTIONSTRING"],
      app_settings["WEBSITE_CONTENTSHARE"],
      app_settings["WEBSITE_MOUNT_ENABLED"],
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
      app_settings["FUNCTIONS_EXTENSION_VERSION"],
      app_settings["FUNCTIONS_WORKER_RUNTIME"],
    ]
  }
}
resource "azurerm_eventgrid_event_subscription" "evtFileReceived" {
  name       = "evtFileReceived"
  scope      = azurerm_storage_account.inbox_storage_account.id
  labels     = ["azure-functions-event-grid-terraform"]
  azure_function_endpoint {
    function_id =  "${azurerm_linux_function_app.function_app.id}/functions/eventGridTrigger"
    # defaults, specified to avoid "no-op" changes when 'apply' is re-ran
    max_events_per_batch              = 1
    preferred_batch_size_in_kilobytes = 64
  }
}
