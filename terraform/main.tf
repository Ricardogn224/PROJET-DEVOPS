terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg-ESGI-DevOps" {
  name     = "rg-ESGI-DevOps"
  location = "westeurope"
}

resource "azurerm_kubernetes_cluster" "kubernetes-cluster" {
  name                = "kubernetes_cluster"
  location            = azurerm_resource_group.rg-ESGI-DevOps.location
  resource_group_name = azurerm_resource_group.rg-ESGI-DevOps.name
  dns_prefix          = "your-aks-dns-prefix"

  default_node_pool {
    name       = "default"
    node_count =1
    vm_size    = "Standard_B2s"
    os_disk_size_gb = 30
  }

  tags = {
    Environment = "Production"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "acr_pull_role" {
  scope                = azurerm_container_registry.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = "e5d93d60-b61b-4767-9e76-8ab3e41a9bd5"  
}

resource "azurerm_role_assignment" "acr_push_role" {
  scope                = azurerm_container_registry.container_registry.id
  role_definition_name = "AcrPush"
  principal_id         = "e5d93d60-b61b-4767-9e76-8ab3e41a9bd5"  
}

resource "azurerm_container_registry" "container_registry" {
  name                     = "mycontainerregistry224"  # Change this name
  resource_group_name      = azurerm_resource_group.rg-ESGI-DevOps.name
  location                 = azurerm_resource_group.rg-ESGI-DevOps.location
  sku                      = "Standard"
  admin_enabled            = true
}

data "external" "get_kube_config" {
  program = ["az", "aks", "get-credentials", "--name", azurerm_kubernetes_cluster.kubernetes-cluster.name, "--resource-group", azurerm_resource_group.rg-ESGI-DevOps.name]
}

output "kubernetes_cluster_ip" {
  value = "${data.external.get_kube_config.result}"
}
