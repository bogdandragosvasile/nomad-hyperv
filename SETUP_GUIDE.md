# Complete Setup Guide

This guide provides step-by-step instructions for setting up the Nomad + Consul Jenkins environment.

## 🚀 Quick Start (Recommended)

### Windows Users
```powershell
# 1. Clone the repository
git clone <your-repo>
cd nomad-hyperv

# 2. Run as Administrator
# Right-click PowerShell and select "Run as administrator"
.\bootstrap.ps1

# 3. Access Jenkins
# Open browser to http://localhost:8080
# Username: admin, Password: admin
```

### Linux/macOS Users
```bash
# 1. Clone the repository
git clone <your-repo>
cd nomad-hyperv

# 2. Make scripts executable
chmod +x *.sh

# 3. Run bootstrap
./bootstrap.sh

# 4. Access Jenkins
# Open browser to http://localhost:8080
# Username: admin, Password: admin
```

## 📋 Prerequisites

### Windows
- **Windows 11/10** with Hyper-V enabled
- **Docker Desktop** installed and running
- **PowerShell 5.1+** (usually pre-installed)
- **Git** for Windows
- **Administrator privileges** (required for Hyper-V and Docker)

### Linux/macOS
- **Docker** and **Docker Compose** installed
- **Git** installed
- **OpenSSH** (for SSH key generation)
- **curl** (for health checks)

## 🔧 Manual Setup (If Automated Scripts Fail)

### 1. Start Jenkins Master
```bash
cd ci/jenkins-bootstrap
docker-compose up -d jenkins
```

### 2. Wait for Jenkins to Start
```bash
# Check if Jenkins is ready
curl -f http://localhost:8080/login
```

### 3. Start Jenkins Agent
```bash
# Start the Linux agent
docker-compose --profile agent up -d jenkins-agent

# Check agent status
curl -s http://localhost:8080/computer/nomad-consul-agent/api/json
```

### 4. Setup Windows Agent (Optional)
```powershell
# Navigate to Windows agent setup
cd ci/windows-agent-setup

# Install Java
.\install-java.ps1

# Install tools
.\install-tools.ps1

# Start agent
.\start-windows-agent.ps1
```

## 🛠️ Management Commands

### Start Environment
```bash
# Linux/macOS
./bootstrap.sh

# Windows
.\bootstrap.ps1
```

### Stop Environment
```bash
# Linux/macOS
./stop.sh

# Windows
.\stop.ps1
```

### Restart Environment
```bash
# Linux/macOS
./restart.sh

# Windows
.\restart.ps1
```

### Check Status
```bash
# Linux/macOS
./status.sh

# Windows
.\status.ps1
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Docker Not Running
```bash
# Start Docker Desktop (Windows)
# Or start Docker service (Linux)
sudo systemctl start docker
```

#### 2. Port 8080 Already in Use
```bash
# Find process using port 8080
netstat -ano | findstr :8080  # Windows
lsof -i :8080                 # Linux/macOS

# Kill the process or change port in docker-compose.yml
```

#### 3. Jenkins Agent Not Connecting
```bash
# Check agent logs
docker-compose -f ci/jenkins-bootstrap/docker-compose.yml logs jenkins-agent

# Restart agent
docker-compose -f ci/jenkins-bootstrap/docker-compose.yml restart jenkins-agent
```

#### 4. Permission Issues (Linux/macOS)
```bash
# Make scripts executable
chmod +x *.sh

# Fix Docker permissions
sudo usermod -aG docker $USER
# Log out and back in
```

#### 5. Hyper-V Not Available (Windows)
```powershell
# Enable Hyper-V
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# Restart computer
Restart-Computer
```

### Logs and Debugging

#### View Jenkins Logs
```bash
# All services
docker-compose -f ci/jenkins-bootstrap/docker-compose.yml logs -f

# Specific service
docker-compose -f ci/jenkins-bootstrap/docker-compose.yml logs -f jenkins
docker-compose -f ci/jenkins-bootstrap/docker-compose.yml logs -f jenkins-agent
```

#### Check Container Status
```bash
# All containers
docker ps -a

# Jenkins containers only
docker ps -a --filter "name=nomad-consul"
```

#### Check Network Connectivity
```bash
# Test Jenkins connectivity
curl -I http://localhost:8080

# Test agent connectivity
curl -s http://localhost:8080/computer/nomad-consul-agent/api/json
```

## 🔐 Security Considerations

### SSH Keys
- SSH keys are automatically generated in `~/.ssh/` (Linux/macOS) or `%USERPROFILE%\.ssh\` (Windows)
- Add the public key to your VMs for Ansible access
- Keep private keys secure

### Jenkins Credentials
- Default credentials are `admin/admin`
- Change these in production environments
- Use Jenkins credential store for sensitive data

### Network Security
- Jenkins is accessible on `localhost:8080` only
- Use nginx reverse proxy for external access
- Configure firewall rules as needed

## 📊 Monitoring

### Health Checks
```bash
# Jenkins health
curl -f http://localhost:8080/login

# Agent health
curl -s http://localhost:8080/computer/nomad-consul-agent/api/json | grep offline
```

### Resource Usage
```bash
# Container resource usage
docker stats

# System resource usage
# Windows: Task Manager
# Linux: htop or top
# macOS: Activity Monitor
```

## 🚀 Next Steps

After successful setup:

1. **Access Jenkins UI** at http://localhost:8080
2. **Create your first pipeline** using the provided Jenkinsfile
3. **Configure your infrastructure** using Terraform
4. **Set up your cluster** using Ansible
5. **Deploy workloads** using Nomad

## 📚 Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Docker Documentation](https://docs.docker.com/)
- [Terraform Documentation](https://www.terraform.io/docs/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Nomad Documentation](https://www.nomadproject.io/docs/)
- [Consul Documentation](https://www.consul.io/docs/)

## 🆘 Getting Help

If you encounter issues:

1. **Check the logs** using the commands above
2. **Review this guide** for common solutions
3. **Check the repository issues** for known problems
4. **Create a new issue** with detailed error information

## 📝 Contributing

To contribute to this project:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

**Happy automating! 🎉**
