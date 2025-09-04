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
- **Windows**: Windows 11/10 with Hyper-V enabled, Docker Desktop, PowerShell 5.1+
- **Linux/macOS**: Docker, Docker Compose, Git, OpenSSH
- **Git**: For cloning the repository

### One-Command Setup

#### Windows (PowerShell as Administrator)
```powershell
# Clone and bootstrap
git clone <your-repo>
cd nomad-hyperv
.\bootstrap.ps1

# Access Jenkins at http://localhost:8080
# Default credentials: admin/admin
```

#### Linux/macOS
```bash
# Clone and bootstrap
git clone <your-repo>
cd nomad-hyperv
chmod +x *.sh
./bootstrap.sh

# Access Jenkins at http://localhost:8080
# Default credentials: admin/admin
```

### Management Commands

#### Windows
```powershell
# Start Jenkins environment
.\bootstrap.ps1

# Stop Jenkins environment
.\stop.ps1

# Restart Jenkins environment
.\restart.ps1

# Check status
.\status.ps1
```

#### Linux/macOS
```bash
# Start Jenkins environment
./bootstrap.sh

# Stop Jenkins environment
./stop.sh

# Restart Jenkins environment
./restart.sh

# Check status
./status.sh
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
