locals {
  location="westeurope"
  env = "test"
}

# resource "azurerm_resource_group" "rg" {
#   name = var.resource-group-name
#   location = var.location
# }

# Create a Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = var.resource-group-name
  location            = var.location
  size                = var.vm-size
  admin_username      = var.admin_user
  network_interface_ids = [
    azurerm_network_interface.itr-01.id,
  ]

  admin_ssh_key {
    username   = var.admin_user
    public_key = tls_private_key.linuxkey.public_key_openssh
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
  depends_on=[
    tls_private_key.linuxkey,
    azurerm_network_interface.itr-01

  ]
}
resource "tls_private_key" "linuxkey" {
  algorithm ="RSA"
  rsa_bits = 4096
}


resource "local_file" "linuxpremkey" {
  filename="linuxkey.pem"
  content = tls_private_key.linuxkey.private_key_pem
  depends_on= [tls_private_key.linuxkey]
}


resource "azurerm_virtual_network" "vrNet-01" {
  name                = "vrNet-01"
  location            = var.location
  resource_group_name = var.resource-group-name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = local.env
  }
  
}
resource "azurerm_subnet" "subnet-01" {
  name                 = "subnet-01"
  resource_group_name  = var.resource-group-name
  virtual_network_name = azurerm_virtual_network.vrNet-01.name
  address_prefixes     = ["10.0.1.0/24"]

}

resource "azurerm_subnet" "subnet-02" {
  name                 = "subnet-01"
  resource_group_name  = var.resource-group-name
  virtual_network_name = azurerm_virtual_network.vrNet-01.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_public_ip" "pubIp-01" {
  name                    = "public-ip-01"
  location                = var.location
  resource_group_name     = var.resource-group-name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30

  tags = {
    environment = local.env
  }
}

resource "azurerm_network_interface" "itr-01" {
  name                = "interface-01"
  location            = var.location
  resource_group_name = var.resource-group-name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet-01.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pubIp-01.id
  }
  depends_on = [ azurerm_subnet.subnet-01,azurerm_public_ip.pubIp-01 ]
}



resource "azurerm_network_security_group" "secrty-Group01" {
  name                = "acceptanceTestSecurityGroup1"
  location            = var.location
  resource_group_name = var.resource-group-name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = local.env
  }
  
}

# resource "azurerm_subnet_network_security_group_association" "grouSubSec-01" {
#   subnet_id                 = azurerm_subnet.subnet-01.id
#   network_security_group_id = azurerm_network_security_group.secrty-Group01.id
# }

output "vm_public_ip" {
  description = "The public IP address of the VM"
  value       = azurerm_public_ip.pubIp-01.ip_address
}
