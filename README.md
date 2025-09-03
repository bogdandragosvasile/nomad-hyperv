# Nomad + Consul HA Cluster on Hyper-V

A complete Infrastructure as Code (IaC) solution for deploying a highly available Nomad and Consul cluster on Windows Hyper-V, orchestrated by Jenkins pipelines.

## 🏗️ Architecture Overview

This repository provides a complete automation pipeline for:
- **Infrastructure**: Hyper-V VM provisioning via Terraform
- **Configuration**: Ansible-based cluster setup and configuration
- **Orchestration**: Jenkins CI/CD pipelines for full lifecycle management
- **Workloads**: Example applications and monitoring for cluster validation

## 🚀 Quick Start

### Prerequisites
- Windows 11/10 with Hyper-V enabled
- Docker Desktop
- Git

### One-Command Setup
```bash
# Clone and bootstrap
git clone <your-repo>
cd nomad-hyperv
docker-compose -f ci/jenkins-bootstrap/docker-compose.yml up -d

# Access Jenkins at http://localhost:8080
# Run the "Bootstrap Cluster" pipeline
```

## 📁 Repository Structure

```
├── docs/           # Architecture and operational documentation
├── infra/          # Terraform infrastructure definitions
├── config/         # Ansible configuration management
├── workloads/      # Example Nomad jobs and applications
├── ci/            # Jenkins pipelines and agent configuration
└── .gitignore     # Git ignore patterns
```

## 🔄 Workflow

1. **Provision** → Terraform creates Hyper-V VMs and networking
2. **Configure** → Ansible sets up Consul HA and Nomad cluster
3. **Deploy** → Jenkins deploys test workloads to validate cluster
4. **Monitor** → Consul UI and Nomad UI provide cluster visibility

## 📚 Documentation

- [Architecture Guide](docs/architecture.md) - High-level system design
- [Networking Strategy](docs/networking.md) - VM networking and connectivity
- [Pipeline Documentation](docs/pipeline.md) - CI/CD process details

## 🛠️ Development

### Local Development
```bash
# Test Terraform locally
cd infra/terraform
terraform init
terraform plan

# Test Ansible locally
cd config/ansible
ansible-playbook -i inventories/dev/hosts.yaml playbooks/common.yaml
```

### Adding New Workloads
1. Create new directory in `workloads/`
2. Add `nomad-job.hcl` file
3. Update Jenkins pipeline to include new workload
4. Test via Jenkins pipeline

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Make changes following IaC principles
4. Test via Jenkins pipeline
5. Submit pull request

## 📄 License

MIT License - see LICENSE file for details

## 🆘 Support

- Check [Issues](../../issues) for known problems
- Review [Documentation](docs/) for detailed guides
- Create new issue for bugs or feature requests
