# Architecture Overview

## System Architecture

This document describes the high-level architecture of the Nomad + Consul HA cluster running on Hyper-V.

## 🏗️ High-Level Design

```
┌─────────────────────────────────────────────────────────────────┐
│                        Windows 11 Host                         │
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐ │
│  │   Jenkins       │    │   Hyper-V       │    │   Terraform │ │
│  │   (Docker)      │    │   Manager       │    │   CLI       │ │
│  └─────────────────┘    └─────────────────┘    └─────────────┘ │
│           │                       │                    │        │
│           └───────────────────────┼────────────────────┘        │
│                                   │                             │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    Hyper-V Network                         │ │
│  │                                                             │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │ │
│  │  │ Consul      │  │ Nomad       │  │ Nomad       │        │ │
│  │  │ Server 1    │  │ Server 1    │  │ Client 1    │        │ │
│  │  │ (VM)        │  │ (VM)        │  │ (VM)        │        │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘        │ │
│  │                                                             │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │ │
│  │  │ Consul      │  │ Nomad       │  │ Nomad       │        │ │
│  │  │ Server 2    │  │ Server 2    │  │ Client 2    │        │ │
│  │  │ (VM)        │  │ (VM)        │  │ (VM)        │        │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘        │ │
│  │                                                             │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │ │
│  │  │ Consul      │  │ Nomad       │  │ Nomad       │        │ │
│  │  │ Server 3    │  │ Server 3    │  │ Client 3    │        │ │
│  │  │ (VM)        │  │ (VM)        │  │ (VM)        │        │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘        │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 🖥️ VM Specifications

### Consul Servers (3x)
- **OS**: Ubuntu 22.04 LTS
- **CPU**: 2 vCPUs
- **Memory**: 4GB RAM
- **Storage**: 40GB
- **Purpose**: Consul HA quorum for service discovery and key-value store

### Nomad Servers (3x)
- **OS**: Ubuntu 22.04 LTS
- **CPU**: 2 vCPUs
- **Memory**: 4GB RAM
- **Storage**: 40GB
- **Purpose**: Nomad cluster management and job scheduling

### Nomad Clients (3x)
- **OS**: Ubuntu 22.04 LTS
- **CPU**: 4 vCPUs
- **Memory**: 8GB RAM
- **Storage**: 60GB
- **Purpose**: Job execution and workload hosting

## 🌐 Networking

### Network Configuration
- **Switch Type**: External (bridged to host network)
- **IP Range**: 192.168.1.100-192.168.1.120
- **Subnet**: 192.168.1.0/24
- **Gateway**: 192.168.1.1
- **DNS**: 8.8.8.8, 8.8.4.4

### Port Assignments
- **Consul**: 8500 (HTTP), 8501 (HTTPS), 8300-8302 (LAN/WAN/Server)
- **Nomad**: 4646 (HTTP), 4647 (HTTPS), 4648 (RPC)
- **Jenkins**: 8080 (HTTP)

## 🔄 Data Flow

### 1. Infrastructure Provisioning
```
Jenkins → Terraform → Hyper-V → VM Creation
```

### 2. Configuration Management
```
Jenkins → Ansible → VM Configuration → Consul/Nomad Setup
```

### 3. Service Discovery
```
Applications → Consul → Service Registration → Health Checks
```

### 4. Job Orchestration
```
Jenkins → Nomad → Job Scheduling → Client Execution
```

## 🛡️ High Availability Features

### Consul HA
- **Quorum**: 3 server nodes (survives 1 node failure)
- **Leader Election**: Automatic failover
- **Data Replication**: Synchronous replication across servers

### Nomad HA
- **Server Quorum**: 3 server nodes (survives 1 node failure)
- **Client Failover**: Automatic job rescheduling
- **State Persistence**: Consul-backed state storage

## 📊 Monitoring & Observability

### Built-in UIs
- **Consul UI**: http://consul-server:8500
- **Nomad UI**: http://nomad-server:4646

### Metrics Collection
- **Consul**: Built-in metrics endpoint
- **Nomad**: Prometheus metrics export
- **System**: Node exporter for host metrics

## 🔧 Automation Pipeline

### Jenkins Pipeline Stages
1. **Validate**: Check prerequisites and configuration
2. **Provision**: Terraform infrastructure creation
3. **Configure**: Ansible cluster setup
4. **Deploy**: Test workload deployment
5. **Verify**: Cluster health and functionality validation

### Rollback Strategy
- **Infrastructure**: Terraform state management
- **Configuration**: Ansible idempotent playbooks
- **Applications**: Nomad job versioning and rollback

## 🚀 Scaling Considerations

### Horizontal Scaling
- **Consul**: Add more server nodes (odd number)
- **Nomad**: Add more client nodes for capacity
- **Load Balancing**: HAProxy or Nginx for external access

### Vertical Scaling
- **Memory**: Increase VM memory allocation
- **CPU**: Add more vCPUs to VMs
- **Storage**: Expand disk capacity

## 🔐 Security

### Network Security
- **Firewall**: UFW on Ubuntu VMs
- **VPN**: Optional WireGuard for remote access
- **Isolation**: Separate network segments if needed

### Access Control
- **Consul**: ACLs for service access control
- **Nomad**: Namespace and policy-based access
- **Jenkins**: Role-based access control
