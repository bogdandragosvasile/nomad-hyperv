# Main Terraform configuration for Nomad + Consul cluster on Hyper-V
# Terraform and provider configuration is in provider.tf

# Variables are defined in variables.tf

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
    controller_number = 0
    controller_location = 0
    path = "${var.base_image_path}"
  }
  
  dvd_drives {
    controller_number = 1
    controller_location = 0
    path = ""
  }
  
  vm_firmware {
    enable_secure_boot = "On"
    secure_boot_template = "MicrosoftUEFICertificateAuthority"
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
    controller_number = 0
    controller_location = 0
    path = "${var.base_image_path}"
  }
  
  dvd_drives {
    controller_number = 1
    controller_location = 0
    path = ""
  }
  
  vm_firmware {
    enable_secure_boot = "On"
    secure_boot_template = "MicrosoftUEFICertificateAuthority"
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
    controller_number = 0
    controller_location = 0
    path = "${var.base_image_path}"
  }
  
  dvd_drives {
    controller_number = 1
    controller_location = 0
    path = ""
  }
  
  vm_firmware {
    enable_secure_boot = "On"
    secure_boot_template = "MicrosoftUEFICertificateAuthority"
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
