locals {
  resource-group-name=""
  location=""
}

resource "azurerm_virtual_network" "vrNet-01" {
  name                = "vrNet-01"
  location            = local.location
  resource_group_name = local.resource-group-name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "test"
  }
  
}
resource "azurerm_subnet" "subnet-01" {
  name                 = "subnet-01"
  resource_group_name  = local.resource-group-name
  virtual_network_name = azurerm_virtual_network.vrNet-01.name
  address_prefixes     = ["10.0.1.0/24"]

}

resource "azurerm_subnet" "subnet-02" {
  name                 = "subnet-01"
  resource_group_name  = local.resource-group-name
  virtual_network_name = azurerm_virtual_network.vrNet-01.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_public_ip" "pubIp-01" {
  name                    = "public-ip-01"
  location                = local.location
  resource_group_name     = local.resource-group-name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30

  tags = {
    environment = "test"
  }
}

resource "azurerm_network_interface" "itr-01" {
  name                = "interface-01"
  location            = local.resource-group-name
  resource_group_name = local.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet-01.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pubIp-01.id
  }
  depends_on = [ azurerm_subnet.subnet-01,azurerm_public_ip.pubIp-01 ]
}



