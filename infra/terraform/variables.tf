# Terraform variables for Nomad + Consul cluster

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "nomad-consul"
}

variable "vm_count" {
  description = "Number of VMs to create for each role"
  type        = number
  default     = 3
  validation {
    condition     = var.vm_count >= 3 && var.vm_count % 2 == 1
    error_message = "VM count must be at least 3 and odd for HA quorum."
  }
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

variable "vm_subnet" {
  description = "Subnet mask for VMs"
  type        = string
  default     = "255.255.255.0"
}

variable "vm_gateway" {
  description = "Gateway IP for VMs"
  type        = string
  default     = "192.168.1.1"
}

variable "vm_dns" {
  description = "DNS servers for VMs"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "ssh_username" {
  description = "SSH username for VM access"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "consul_version" {
  description = "Consul version to install"
  type        = string
  default     = "1.16.0"
}

variable "nomad_version" {
  description = "Nomad version to install"
  type        = string
  default     = "1.6.0"
}

variable "enable_monitoring" {
  description = "Enable monitoring and observability"
  type        = bool
  default     = true
}

variable "enable_security" {
  description = "Enable security features (ACLs, TLS)"
  type        = bool
  default     = false
}

variable "backup_enabled" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "nomad-consul"
    ManagedBy   = "terraform"
    Owner       = "devops-team"
  }
}
