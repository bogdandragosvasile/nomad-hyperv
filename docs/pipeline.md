# CI/CD Pipeline Documentation

## Pipeline Overview

This document describes the Jenkins CI/CD pipeline that orchestrates the complete lifecycle of the Nomad + Consul cluster.

## 🔄 Pipeline Architecture

### Pipeline Flow
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Validate  │ →  │  Provision  │ →  │  Configure  │ →  │   Deploy    │
│             │    │             │    │             │    │             │
│ • Check     │    │ • Terraform │    │ • Ansible   │    │ • Nomad     │
│   prereqs   │    │ • Hyper-V   │    │ • Consul    │    │   Jobs      │
│ • Validate  │    │ • VM        │    │ • Nomad     │    │ • Test      │
│   config    │    │   Creation  │    │ • Cluster   │    │   Workloads │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

### Pipeline Stages
1. **Validate** → Check prerequisites and configuration
2. **Provision** → Create infrastructure with Terraform
3. **Configure** → Setup cluster with Ansible
4. **Deploy** → Deploy test workloads to Nomad
5. **Verify** → Validate cluster functionality

## 🏗️ Jenkins Setup

### Jenkins Server
- **Container**: Docker-based Jenkins server
- **Port**: 8080
- **Plugins**: Git, Pipeline, Docker, Credentials
- **Credentials**: SSH keys for VM access

### Jenkins Agent
- **Container**: Custom Docker image with tools
- **Tools**: Terraform, Ansible, Nomad CLI, Consul CLI
- **Base**: Ubuntu 22.04 with Python 3.10+

## 📋 Pipeline Configuration

### Main Jenkinsfile
```groovy
pipeline {
    agent any
    
    environment {
        TF_WORKSPACE = 'nomad-cluster'
        ANSIBLE_INVENTORY = 'config/ansible/inventories/dev'
        NOMAD_ADDR = 'http://192.168.1.103:4646'
        CONSUL_ADDR = 'http://192.168.1.100:8500'
    }
    
    stages {
        stage('Validate') {
            steps {
                script {
                    validatePrerequisites()
                }
            }
        }
        
        stage('Provision') {
            steps {
                script {
                    provisionInfrastructure()
                }
            }
        }
        
        stage('Configure') {
            steps {
                script {
                    configureCluster()
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    deployWorkloads()
                }
            }
        }
        
        stage('Verify') {
            steps {
                script {
                    verifyCluster()
                }
            }
        }
    }
    
    post {
        always {
            cleanup()
        }
        success {
            notifySuccess()
        }
        failure {
            notifyFailure()
        }
    }
}
```

## 🔧 Pipeline Functions

### Validation Functions
```groovy
def validatePrerequisites() {
    // Check Hyper-V availability
    powershell 'Get-WindowsFeature -Name Hyper-V-All'
    
    // Check Docker availability
    sh 'docker --version'
    
    // Check required tools
    sh 'terraform --version'
    sh 'ansible --version'
}
```

### Provisioning Functions
```groovy
def provisionInfrastructure() {
    dir('infra/terraform') {
        // Initialize Terraform
        sh 'terraform init'
        
        // Plan changes
        sh 'terraform plan -out=tfplan'
        
        // Apply changes
        sh 'terraform apply tfplan'
        
        // Get outputs
        sh 'terraform output -json > outputs.json'
    }
}
```

### Configuration Functions
```groovy
def configureCluster() {
    dir('config/ansible') {
        // Setup Consul cluster
        sh 'ansible-playbook -i inventories/dev/hosts.yaml playbooks/setup-consul.yaml'
        
        // Setup Nomad cluster
        sh 'ansible-playbook -i inventories/dev/hosts.yaml playbooks/setup-nomad.yaml'
        
        // Verify cluster health
        sh 'ansible-playbook -i inventories/dev/hosts.yaml playbooks/verify-cluster.yaml'
    }
}
```

### Deployment Functions
```groovy
def deployWorkloads() {
    // Deploy example service
    dir('workloads/example-service') {
        sh 'nomad job run nomad-job.hcl'
    }
    
    // Deploy monitoring
    dir('workloads/monitoring') {
        sh 'nomad job run nomad-job.hcl'
    }
    
    // Wait for deployment
    sh 'nomad job status -verbose example-service'
}
```

## 📊 Pipeline Monitoring

### Success Criteria
- [ ] All VMs created and accessible
- [ ] Consul cluster healthy (3/3 servers)
- [ ] Nomad cluster healthy (3/3 servers, 3/3 clients)
- [ ] Test workloads deployed successfully
- [ ] All services responding to health checks

### Failure Handling
- **Infrastructure Failures**: Terraform rollback
- **Configuration Failures**: Ansible retry with increased verbosity
- **Deployment Failures**: Nomad job rollback
- **Network Issues**: Diagnostic commands and troubleshooting

### Rollback Strategy
```groovy
def rollbackInfrastructure() {
    dir('infra/terraform') {
        sh 'terraform destroy -auto-approve'
    }
}

def rollbackConfiguration() {
    dir('config/ansible') {
        sh 'ansible-playbook -i inventories/dev/hosts.yaml playbooks/rollback.yaml'
    }
}
```

## 🔐 Security Considerations

### Credential Management
- **SSH Keys**: Stored in Jenkins credentials
- **API Tokens**: Consul and Nomad ACL tokens
- **Secrets**: Vault integration for sensitive data

### Access Control
- **Pipeline Permissions**: Role-based access control
- **VM Access**: SSH key-based authentication
- **Service Access**: Consul ACLs and Nomad policies

## 📈 Pipeline Optimization

### Performance Improvements
- **Parallel Execution**: Concurrent VM provisioning
- **Caching**: Terraform state and Ansible facts
- **Artifact Management**: Store and reuse build artifacts

### Monitoring and Alerting
- **Pipeline Metrics**: Success/failure rates, duration
- **Cluster Health**: Automated health checks
- **Notifications**: Slack/Email alerts for failures

## 🧪 Testing Strategy

### Unit Testing
- **Terraform**: `terraform validate` and `terraform plan`
- **Ansible**: `ansible-lint` and syntax checking
- **Nomad Jobs**: `nomad job validate`

### Integration Testing
- **Cluster Health**: Automated health checks
- **Service Discovery**: Consul service registration tests
- **Job Execution**: Nomad job deployment tests

### End-to-End Testing
- **Full Pipeline**: Complete infrastructure deployment
- **Workload Validation**: Application functionality tests
- **Failure Scenarios**: Disaster recovery testing

## 📋 Pipeline Checklist

### Pre-deployment
- [ ] Jenkins server running and accessible
- [ ] Required plugins installed
- [ ] Credentials configured
- [ ] Repository cloned and accessible

### Pipeline Execution
- [ ] Validation stage passes
- [ ] Infrastructure provisioned successfully
- [ ] Cluster configured and healthy
- [ ] Workloads deployed and running
- [ ] All health checks passing

### Post-deployment
- [ ] Documentation updated
- [ ] Monitoring configured
- [ ] Backup strategy implemented
- [ ] Rollback procedures documented
