locals {
  location="westeurope"
  env = "test"
}

resource "azurerm_resource_group" "rg" {
  name = var.resource-group-name
  location = var.location
}

# Create a Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = vm.size
  admin_username      = var.admin_user
  network_interface_ids = [
    azurerm_network_interface.itr-01.id,
  ]

  admin_ssh_key {
    username   = var.admin_user
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_virtual_network" "vrNet-01" {
  name                = "vrNet-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = local.env
  }
  
}
resource "azurerm_subnet" "subnet-01" {
  name                 = "subnet-01"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vrNet-01.name
  address_prefixes     = ["10.0.1.0/24"]

}

resource "azurerm_subnet" "subnet-02" {
  name                 = "subnet-01"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vrNet-01.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_public_ip" "pubIp-01" {
  name                    = "public-ip-01"
  location                = var.location
  resource_group_name     = azurerm_resource_group.rg.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30

  tags = {
    environment = local.env
  }
}

resource "azurerm_network_interface" "itr-01" {
  name                = "interface-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet-01.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pubIp-01.id
  }
  depends_on = [ azurerm_subnet.subnet-01,azurerm_public_ip.pubIp-01 ]
}



