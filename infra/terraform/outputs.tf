# Terraform outputs for Nomad + Consul cluster

output "consul_servers" {
  description = "Consul server VM information"
  value = {
    names = [for vm in hyperv_machine_instance.consul_servers : vm.name]
    ips   = [for i, vm in hyperv_machine_instance.consul_servers : "192.168.1.${100 + i}"]
    state = [for vm in hyperv_machine_instance.consul_servers : vm.state]
  }
}

output "nomad_servers" {
  description = "Nomad server VM information"
  value = {
    names = [for vm in hyperv_machine_instance.nomad_servers : vm.name]
    ips   = [for i, vm in hyperv_machine_instance.nomad_servers : "192.168.1.${103 + i}"]
    state = [for vm in hyperv_machine_instance.nomad_servers : vm.state]
  }
}

output "nomad_clients" {
  description = "Nomad client VM information"
  value = {
    names = [for vm in hyperv_machine_instance.nomad_clients : vm.name]
    ips   = [for i, vm in hyperv_machine_instance.nomad_clients : "192.168.1.${106 + i}"]
    state = [for vm in hyperv_machine_instance.nomad_clients : vm.state]
  }
}

output "cluster_info" {
  description = "Complete cluster information"
  value = {
    total_vms = var.vm_count * 3
    consul_servers = var.vm_count
    nomad_servers = var.vm_count
    nomad_clients = var.vm_count
    network_range = "${var.vm_ip_range}/24"
    gateway = var.vm_gateway
    dns_servers = var.vm_dns
  }
}

output "access_urls" {
  description = "Access URLs for cluster services"
  value = {
    consul_ui = "http://192.168.1.100:8500"
    nomad_ui = "http://192.168.1.103:4646"
    jenkins = "http://localhost:8080"
  }
}

output "ssh_commands" {
  description = "SSH commands for accessing VMs"
  value = {
    consul_server_1 = "ssh ${var.ssh_username}@192.168.1.100"
    consul_server_2 = "ssh ${var.ssh_username}@192.168.1.101"
    consul_server_3 = "ssh ${var.ssh_username}@192.168.1.102"
    nomad_server_1 = "ssh ${var.ssh_username}@192.168.1.103"
    nomad_server_2 = "ssh ${var.ssh_username}@192.168.1.104"
    nomad_server_3 = "ssh ${var.ssh_username}@192.168.1.105"
    nomad_client_1 = "ssh ${var.ssh_username}@192.168.1.106"
    nomad_client_2 = "ssh ${var.ssh_username}@192.168.1.107"
    nomad_client_3 = "ssh ${var.ssh_username}@192.168.1.108"
  }
}

output "consul_cluster_status" {
  description = "Commands to check Consul cluster status"
  value = {
    members = "consul members -http-addr=http://192.168.1.100:8500"
    info = "consul info -http-addr=http://192.168.1.100:8500"
    catalog = "consul catalog services -http-addr=http://192.168.1.100:8500"
  }
}

output "nomad_cluster_status" {
  description = "Commands to check Nomad cluster status"
  value = {
    members = "nomad server members -address=http://192.168.1.103:4646"
    nodes = "nomad node status -address=http://192.168.1.103:4646"
    jobs = "nomad job status -address=http://192.168.1.103:4646"
  }
}

output "monitoring_endpoints" {
  description = "Monitoring and metrics endpoints"
  value = var.enable_monitoring ? {
    consul_metrics = "http://192.168.1.100:8500/v1/agent/metrics"
    nomad_metrics = "http://192.168.1.103:4646/v1/metrics"
    node_exporter = "http://192.168.1.100:9100/metrics"
  } : null
}

output "backup_info" {
  description = "Backup configuration information"
  value = var.backup_enabled ? {
    enabled = true
    retention_days = var.backup_retention_days
    backup_path = "C:\\Backups\\nomad-consul"
  } : {
    enabled = false
  }
}

output "security_info" {
  description = "Security configuration information"
  value = {
    acls_enabled = var.enable_security
    tls_enabled = var.enable_security
    ssh_key_path = var.ssh_public_key
  }
}
