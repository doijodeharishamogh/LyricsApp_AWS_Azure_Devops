# Configure the Microsoft Azure Provider
provider "azurerm" {
    version = "=2.0.0"
    features {}
}

# create a resource group 
resource "azurerm_resource_group" "helloterraform" {
    name = "terraformtest"
    location = "East US"
}

# create a virtual network
resource "azurerm_virtual_network" "helloterraformnetwork" {
    name = "acctvn"
    address_space = ["10.0.0.0/16"]
    location = "East US"
    resource_group_name = azurerm_resource_group.helloterraform.name
}

# create subnet
resource "azurerm_subnet" "helloterraformsubnet" {
    name = "acctsub"
    resource_group_name = azurerm_resource_group.helloterraform.name
    virtual_network_name = azurerm_virtual_network.helloterraformnetwork.name
    address_prefix = "10.0.2.0/24"
}

# create public IP
resource "azurerm_public_ip" "helloterraformips" {
    name = "terraformtestip"
    location = "East US"
    resource_group_name = azurerm_resource_group.helloterraform.name
    allocation_method       = "Dynamic"
    tags = {
        environment = "TerraformDemo"
    }
}

# create network interface
resource "azurerm_network_interface" "helloterraformnic" {
    name = "tfni"
    location = "East US"
    resource_group_name = azurerm_resource_group.helloterraform.name

    ip_configuration {
        name = "testconfiguration1"
        subnet_id = azurerm_subnet.helloterraformsubnet.id
        private_ip_address_allocation = "static"
        private_ip_address = "10.0.2.5"
        public_ip_address_id = azurerm_public_ip.helloterraformips.id
    }
}

# create storage account
resource "azurerm_storage_account" "helloterraformstorage" {
    name = "helloterraformstg021020"
    resource_group_name = azurerm_resource_group.helloterraform.name
    location = "East US"
	account_replication_type = "LRS"
	account_tier = "Standard"

    tags = {
        environment = "staging"
    }
}

# create storage container
resource "azurerm_storage_container" "helloterraformstoragestoragecontainer" {
    name = "vhd"
    storage_account_name = azurerm_storage_account.helloterraformstorage.name
    container_access_type = "private"
    depends_on = [azurerm_storage_account.helloterraformstorage]
}

# create virtual machine
resource "azurerm_virtual_machine" "helloterraformvm" {
    name = "terraformvm"
    location = "East US"
    resource_group_name = azurerm_resource_group.helloterraform.name
    network_interface_ids = [azurerm_network_interface.helloterraformnic.id]
    vm_size = "Standard_A0"

    storage_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "18.04-LTS"
        version = "latest"
    }

    storage_os_disk {
        name = "myosdisk"
        vhd_uri = "${azurerm_storage_account.helloterraformstorage.primary_blob_endpoint}${azurerm_storage_container.helloterraformstoragestoragecontainer.name}/myosdisk.vhd"
        caching = "ReadWrite"
        create_option = "FromImage"
    }

    os_profile {
        computer_name = "hostname"
        admin_username = "testadmin"
        admin_password = "Password1234!"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    tags = {
        environment = "staging"
    }
}

resource "azurerm_virtual_machine_extension" "helloterraformex" {
  name                 = "hostname"
  virtual_machine_id   = azurerm_virtual_machine.helloterraformvm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "sudo apt -y update \nsudo apt install -y apt-transport-https ca-certificates curl software-properties-common \ncurl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - \nsudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable\" \nsudo apt -y update \napt-cache policy docker-ce \nsudo apt install -y docker-ce \nsudo systemctl status docker \nsudo docker pull doijoy46/dotnet:v3 \nsudo docker run --name test --rm -d -i -t -p 5000:5000 doijoy46/dotnet:v3"
    }
SETTINGS


  tags = {
    environment = "Production"
  }
}


