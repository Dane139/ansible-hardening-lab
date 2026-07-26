terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}
 
provider "azurerm" {
  features {}
}
 
data "azurerm_client_config" "current" {}

data "http" "my_ip" {
  url = "https://api.ipify.org"
}

resource "azurerm_resource_group" "main" {
  name     = "rg-ansible-hardening-${var.yourname}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-hardening-${var.yourname}"
  address_space       = ["10.20.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}
 
resource "azurerm_subnet" "main" {
  name                 = "subnet-hardening"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.20.1.0/24"]
}

resource "azurerm_network_security_group" "main" {
  name                = "nsg-hardening-${var.yourname}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
 
  security_rule {
    name                       = "AllowSSHFromMe"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${chomp(data.http.my_ip.response_body)}/32"
    destination_address_prefix = "*"
  }
 
  security_rule {
    name                       = "AllowWeb"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
 
  tags = var.tags
}
 
resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_public_ip" "vm" {
  count               = var.vm_count
  name                = "pip-web-${count.index + 1}-${var.yourname}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}
 
resource "azurerm_network_interface" "vm" {
  count               = var.vm_count
  name                = "nic-web-${count.index + 1}-${var.yourname}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
 
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm[count.index].id
  }
 
  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                           = var.vm_count
  name                            = "web-${count.index + 1}-${var.yourname}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  network_interface_ids           = [azurerm_network_interface.vm[count.index].id]
  disable_password_authentication = true
 
  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }
 
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
 
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
 
  tags = var.tags
}

locals {
  inventory_hosts = join("\n", [
    for idx, ip in azurerm_public_ip.vm[*].ip_address :
    "web${idx + 1} ansible_host=${ip}"
  ])
}
 
resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible-hardening/inventory.ini"
  file_permission = "0644"
  content         = <<EOT
[hardened]
${local.inventory_hosts}
 
[hardened:vars]
ansible_user=${var.admin_username}
ansible_ssh_private_key_file=${var.ssh_private_key_path}
ansible_python_interpreter=/usr/bin/python3
EOT
}
