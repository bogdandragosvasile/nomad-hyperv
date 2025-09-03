# Terraform provider configuration for Hyper-V

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    hyperv = {
      source  = "taliesins/hyperv"
      version = "~> 1.0"
    }
  }
  
  # Backend configuration (optional - for team collaboration)
  # backend "local" {
  #   path = "terraform.tfstate"
  # }
  
  # Backend configuration for remote state (recommended for production)
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state-rg"
  #   storage_account_name = "tfstatenomadconsul"
  #   container_name       = "tfstate"
  #   key                 = "nomad-consul.terraform.tfstate"
  # }
}

# Configure Hyper-V provider
provider "hyperv" {
  # No additional configuration needed for local Hyper-V
  # The provider will automatically detect and use the local Hyper-V instance
  
  # Optional: Specify Hyper-V host if running remotely
  # host = "hyperv-host.example.com"
  
  # Optional: Specify credentials if using remote Hyper-V
  # username = "administrator"
  # password = "password"
}

# Configure local-exec provisioner for post-VM creation tasks
provider "local" {
  # Local provider for running commands on the host machine
}

# Configure null provider for data-only resources
provider "null" {
  # Null provider for data-only resources
}
