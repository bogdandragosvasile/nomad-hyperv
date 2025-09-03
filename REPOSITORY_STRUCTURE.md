# Repository Structure Overview

This document provides a complete overview of the Nomad + Consul Hyper-V repository structure.

## 📁 Complete Directory Structure

```
nomad-hyperv/
├── README.md                           # Main project documentation
├── LICENSE                             # MIT License
├── .gitignore                          # Git ignore patterns
├── REPOSITORY_STRUCTURE.md             # This file - complete structure overview
│
├── docs/                               # Documentation
│   ├── architecture.md                 # High-level system architecture
│   ├── networking.md                   # Network topology and configuration
│   └── pipeline.md                     # CI/CD pipeline documentation
│
├── infra/                              # Infrastructure as Code
│   └── terraform/                      # Terraform configurations
│       ├── main.tf                     # Main Terraform configuration
│       ├── variables.tf                # Variable definitions
│       ├── outputs.tf                  # Output definitions
│       └── provider.tf                 # Provider configuration
│
├── config/                             # Configuration Management
│   └── ansible/                        # Ansible playbooks and roles
│       ├── ansible.cfg                 # Ansible configuration
│       ├── inventories/                # Host inventories
│       │   └── dev/                    # Development environment
│       │       └── hosts.yaml          # Host definitions
│       ├── playbooks/                  # Ansible playbooks
│       │   ├── common.yaml             # Common configuration
│       │   ├── setup-consul.yaml       # Consul cluster setup
│       │   └── setup-nomad.yaml        # Nomad cluster setup
│       └── roles/                      # Ansible roles (placeholder)
│           ├── consul/                 # Consul role
│           │   └── tasks/              # Role tasks
│           │       └── main.yaml       # Main role tasks
│           └── nomad/                  # Nomad role
│               └── tasks/              # Role tasks
│                   └── main.yaml       # Main role tasks
│
├── workloads/                          # Example workloads and applications
│   ├── example-service/                # Multi-tier example application
│   │   ├── nomad-job.hcl              # Nomad job specification
│   │   ├── docker/                    # Docker configuration
│   │   │   └── Dockerfile             # Application Dockerfile
│   │   └── README.md                  # Service documentation
│   └── monitoring/                     # Monitoring stack
│       └── nomad-job.hcl              # Monitoring job specification
│
├── ci/                                 # CI/CD Configuration
│   ├── Jenkinsfile                     # Main Jenkins pipeline
│   ├── Dockerfile.agent                # Jenkins agent Dockerfile
│   ├── pipelines/                      # Pipeline definitions (placeholder)
│   │   ├── provision.groovy            # Provisioning pipeline
│   │   ├── configure.groovy            # Configuration pipeline
│   │   └── deploy.groovy              # Deployment pipeline
│   └── jenkins-bootstrap/              # Jenkins server setup
│       ├── docker-compose.yml          # Jenkins server deployment
│       └── plugins.txt                 # Jenkins plugins list
│
└── scripts/                            # Utility scripts (placeholder)
    ├── setup-hyperv.ps1               # Hyper-V setup script
    ├── create-switch.ps1               # Network switch creation
    └── validate-prereqs.ps1            # Prerequisites validation
```

## 🏗️ Architecture Components

### 1. Infrastructure Layer (Terraform)
- **Purpose**: Provision Hyper-V VMs and networking
- **Files**: `infra/terraform/*.tf`
- **Key Features**:
  - 9 VMs (3 Consul servers, 3 Nomad servers, 3 Nomad clients)
  - External network switch configuration
  - Resource allocation (CPU, memory, storage)
  - IP addressing scheme (192.168.1.100-108)

### 2. Configuration Layer (Ansible)
- **Purpose**: Configure cluster nodes and services
- **Files**: `config/ansible/`
- **Key Features**:
  - Common system configuration
  - Consul HA cluster setup
  - Nomad cluster configuration
  - Monitoring tools installation

### 3. Application Layer (Nomad Jobs)
- **Purpose**: Deploy and manage workloads
- **Files**: `workloads/*/nomad-job.hcl`
- **Key Features**:
  - Example multi-tier application
  - Monitoring stack (Prometheus, Grafana, AlertManager)
  - Service discovery integration
  - Health checks and monitoring

### 4. Orchestration Layer (Jenkins)
- **Purpose**: Automate the complete deployment lifecycle
- **Files**: `ci/Jenkinsfile`, `ci/Dockerfile.agent`
- **Key Features**:
  - Multi-stage pipeline (Validate → Provision → Configure → Deploy)
  - Infrastructure validation
  - Automated cluster setup
  - Workload deployment
  - Health verification

## 🔧 Key Configuration Files

### Terraform Configuration
- **`main.tf`**: VM definitions, networking, resource allocation
- **`variables.tf`**: Configurable parameters (VM counts, sizes, versions)
- **`outputs.tf`**: Cluster information and access details
- **`provider.tf`**: Hyper-V provider configuration

### Ansible Configuration
- **`ansible.cfg`**: Performance and security settings
- **`hosts.yaml`**: Inventory with role-based grouping
- **`playbooks/`**: Automated configuration tasks
- **`roles/`**: Reusable configuration modules

### Nomad Jobs
- **`example-service/nomad-job.hcl`**: Web + API + Cache application
- **`monitoring/nomad-job.hcl`**: Prometheus + Grafana + AlertManager

### Jenkins Pipeline
- **`Jenkinsfile`**: Complete deployment orchestration
- **`Dockerfile.agent`**: Tooled Jenkins agent image
- **`docker-compose.yml`**: Local Jenkins server setup

## 🚀 Quick Start Commands

### 1. Clone and Setup
```bash
git clone <repository-url>
cd nomad-hyperv
```

### 2. Start Jenkins
```bash
cd ci/jenkins-bootstrap
docker-compose up -d
```

### 3. Access Jenkins
- URL: http://localhost:8080
- Run the "Bootstrap Cluster" pipeline

### 4. Manual Testing (Optional)
```bash
# Test Terraform
cd infra/terraform
terraform init
terraform plan

# Test Ansible
cd config/ansible
ansible-playbook -i inventories/dev/hosts.yaml playbooks/common.yaml
```

## 📊 Monitoring and Access

### Service URLs
- **Consul UI**: http://192.168.1.100:8500
- **Nomad UI**: http://192.168.1.103:4646
- **Jenkins**: http://localhost:8080
- **Grafana**: http://<node-ip>:3000 (after deployment)
- **Prometheus**: http://<node-ip>:9090 (after deployment)

### Health Checks
- **Consul**: `consul members -http-addr=http://192.168.1.100:8500`
- **Nomad**: `nomad server members -address=http://192.168.1.103:4646`
- **Workloads**: `nomad job status example-service`

## 🔐 Security Considerations

### Access Control
- SSH key-based authentication for VMs
- Jenkins credentials management
- Consul ACLs (optional)
- Nomad policies (optional)

### Network Security
- UFW firewall on Ubuntu VMs
- Port restrictions to necessary services
- External switch isolation

## 📈 Scaling and Extensibility

### Horizontal Scaling
- Increase VM counts in `variables.tf`
- Add new workload types in `workloads/`
- Extend Ansible roles for new services

### Vertical Scaling
- Adjust resource allocations in Terraform
- Modify system limits in Ansible playbooks
- Optimize Nomad job resource requirements

### New Environments
- Create new inventory files (`inventories/prod/`)
- Environment-specific variables
- Separate Terraform workspaces

## 🧪 Testing Strategy

### Unit Testing
- Terraform: `terraform validate` and `terraform plan`
- Ansible: `ansible-lint` and syntax checking
- Nomad: `nomad job validate`

### Integration Testing
- Jenkins pipeline execution
- Cluster health verification
- Workload deployment validation

### End-to-End Testing
- Complete infrastructure deployment
- Service functionality testing
- Disaster recovery scenarios

## 📋 Maintenance and Operations

### Backup Strategy
- Automated VM backups via Ansible
- Configuration backup and versioning
- State file management

### Monitoring and Alerting
- Prometheus metrics collection
- Grafana dashboards
- AlertManager notifications

### Update Procedures
- Rolling updates for cluster nodes
- Blue-green deployment for workloads
- Rollback procedures for failed deployments

## 🤝 Contributing

### Development Workflow
1. Fork the repository
2. Create feature branch
3. Make changes following IaC principles
4. Test via Jenkins pipeline
5. Submit pull request

### Code Standards
- Terraform: Use consistent formatting and naming
- Ansible: Follow playbook best practices
- Nomad: Use job templates and variables
- Documentation: Keep README files updated

This repository provides a complete, production-ready foundation for running a Nomad + Consul cluster on Hyper-V with full automation via Jenkins pipelines.
