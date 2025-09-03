# Main Terraform configuration for Nomad + Consul cluster on Hyper-V

terraform {
  required_version = ">= 1.0"
  required_providers {
    hyperv = {
      source  = "taliesins/hyperv"
      version = "~> 1.0"
    }
  }
}

# Configure Hyper-V provider
provider "hyperv" {
  # Provider configuration for Hyper-V
  # No additional configuration needed for local Hyper-V
}

# Variables
variable "vm_count" {
  description = "Number of VMs to create for each role"
  type        = number
  default     = 3
}

variable "vm_memory" {
  description = "Memory allocation for VMs in MB"
  type        = map(number)
  default = {
    consul_server = 4096
    nomad_server  = 4096
    nomad_client  = 8192
  }
}

variable "vm_cpu" {
  description = "CPU allocation for VMs"
  type        = map(number)
  default = {
    consul_server = 2
    nomad_server  = 2
    nomad_client  = 4
  }
}

variable "vm_storage" {
  description = "Storage allocation for VMs in GB"
  type        = map(number)
  default = {
    consul_server = 40
    nomad_server  = 40
    nomad_client  = 60
  }
}

variable "network_switch" {
  description = "Name of the Hyper-V external switch"
  type        = string
  default     = "External Switch"
}

variable "base_image_path" {
  description = "Path to the base Ubuntu 22.04 VHDX image"
  type        = string
  default     = "C:\\Images\\ubuntu-22.04-server-amd64.vhdx"
}

variable "vm_ip_range" {
  description = "IP range for VMs"
  type        = string
  default     = "192.168.1.100"
}

# Data sources
data "hyperv_network_switch" "external" {
  name = var.network_switch
}

# Local variables for IP addressing
locals {
  consul_servers = [for i in range(var.vm_count) : {
    name = "consul-server-${i + 1}"
    ip   = cidrhost("${var.vm_ip_range}/24", 100 + i)
  }]
  
  nomad_servers = [for i in range(var.vm_count) : {
    name = "nomad-server-${i + 1}"
    ip   = cidrhost("${var.vm_ip_range}/24", 103 + i)
  }]
  
  nomad_clients = [for i in range(var.vm_count) : {
    name = "nomad-client-${i + 1}"
    ip   = cidrhost("${var.vm_ip_range}/24", 106 + i)
  }]
}

# Consul Server VMs
resource "hyperv_machine_instance" "consul_servers" {
  count = var.vm_count
  
  name = local.consul_servers[count.index].name
  
  generation = 2
  
  processor_count = var.vm_cpu.consul_server
  
  dynamic_memory = true
  memory_startup_bytes = var.vm_memory.consul_server * 1024 * 1024
  memory_minimum_bytes = 1024 * 1024 * 1024  # 1GB minimum
  memory_maximum_bytes = var.vm_memory.consul_server * 1024 * 1024 * 2  # 2x startup
  
  network_adaptors {
    name = "Network Adapter"
    switch_name = data.hyperv_network_switch.external.name
  }
  
  hard_disk_drives {
    controller_type = "Scsi"
    controller_number = 0
    controller_location = 0
    path = "${var.base_image_path}"
  }
  
  dvd_drives {
    controller_type = "Scsi"
    controller_number = 1
    controller_location = 0
    path = ""
  }
  
  vm_firmware {
    enable_secure_boot = "On"
    secure_boot_template = "MicrosoftUEFICertificateAuthority"
  }
  
  tags = {
    role = "consul-server"
    environment = "dev"
    managed_by = "terraform"
  }
}

# Nomad Server VMs
resource "hyperv_machine_instance" "nomad_servers" {
  count = var.vm_count
  
  name = local.nomad_servers[count.index].name
  
  generation = 2
  
  processor_count = var.vm_cpu.nomad_server
  
  dynamic_memory = true
  memory_startup_bytes = var.vm_memory.nomad_server * 1024 * 1024
  memory_minimum_bytes = 1024 * 1024 * 1024  # 1GB minimum
  memory_maximum_bytes = var.vm_memory.nomad_server * 1024 * 1024 * 2  # 2x startup
  
  network_adaptors {
    name = "Network Adapter"
    switch_name = data.hyperv_network_switch.external.name
  }
  
  hard_disk_drives {
    controller_type = "Scsi"
    controller_number = 0
    controller_location = 0
    path = "${var.base_image_path}"
  }
  
  dvd_drives {
    controller_type = "Scsi"
    controller_number = 1
    controller_location = 0
    path = ""
  }
  
  vm_firmware {
    enable_secure_boot = "On"
    secure_boot_template = "MicrosoftUEFICertificateAuthority"
  }
  
  tags = {
    role = "nomad-server"
    environment = "dev"
    managed_by = "terraform"
  }
}

# Nomad Client VMs
resource "hyperv_machine_instance" "nomad_clients" {
  count = var.vm_count
  
  name = local.nomad_clients[count.index].name
  
  generation = 2
  
  processor_count = var.vm_cpu.nomad_client
  
  dynamic_memory = true
  memory_startup_bytes = var.vm_memory.nomad_client * 1024 * 1024
  memory_minimum_bytes = 2048 * 1024 * 1024  # 2GB minimum
  memory_maximum_bytes = var.vm_memory.nomad_client * 1024 * 1024 * 2  # 2x startup
  
  network_adaptors {
    name = "Network Adapter"
    switch_name = data.hyperv_network_switch.external.name
  }
  
  hard_disk_drives {
    controller_type = "Scsi"
    controller_number = 0
    controller_location = 0
    path = "${var.base_image_path}"
  }
  
  dvd_drives {
    controller_type = "Scsi"
    controller_number = 1
    controller_location = 0
    path = ""
  }
  
  vm_firmware {
    enable_secure_boot = "On"
    secure_boot_template = "MicrosoftUEFICertificateAuthority"
  }
  
  tags = {
    role = "nomad-client"
    environment = "dev"
    managed_by = "terraform"
  }
}

# Start all VMs
resource "hyperv_machine_instance" "start_consul_servers" {
  count = var.vm_count
  
  name = hyperv_machine_instance.consul_servers[count.index].name
  
  depends_on = [hyperv_machine_instance.consul_servers]
  
  state = "Running"
}

resource "hyperv_machine_instance" "start_nomad_servers" {
  count = var.vm_count
  
  name = hyperv_machine_instance.nomad_servers[count.index].name
  
  depends_on = [hyperv_machine_instance.nomad_servers]
  
  state = "Running"
}

resource "hyperv_machine_instance" "start_nomad_clients" {
  count = var.vm_count
  
  name = hyperv_machine_instance.nomad_clients[count.index].name
  
  depends_on = [hyperv_machine_instance.nomad_clients]
  
  state = "Running"
}
