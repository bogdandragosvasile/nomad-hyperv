# VM Image Preparation Pipeline

This document describes the Jenkins pipeline for preparing Hyper-V VM images with cloud-init configuration, SSH key injection, and networking setup.

## Overview

The pipeline automates the creation of pre-configured Ubuntu VM images that can be deployed to Hyper-V with proper networking and SSH access. This solves the networking issues encountered with the standard Ubuntu cloud images.

## Pipeline Architecture

### 1. Image Preparation Pipeline (`Jenkinsfile-image-prep`)
- **Agent**: Linux agent (for VHD mounting and chroot operations)
- **Purpose**: Creates prepared VM images with cloud-init configuration
- **Output**: Ready-to-deploy VHD files with SSH keys and networking pre-configured

### 2. Deployment Pipeline (`Jenkinsfile-deploy`)
- **Agent**: Windows Hyper-V agent
- **Purpose**: Deploys VMs using the prepared images
- **Output**: Running VMs ready for Ansible configuration

## Features

### SSH Key Injection
- Automatically injects SSH public keys into the image
- Configures SSH server with proper settings
- Enables both key-based and password authentication
- Sets up proper user permissions

### Networking Configuration
- Supports both DHCP and static IP configuration
- Configures DNS servers
- Sets up proper network interfaces
- Ensures networking works on first boot

### Cloud-Init Integration
- Injects user-data, network-config, and meta-data files
- Places files in both `/var/lib/cloud/seed/nocloud-net/` and `/var/lib/cloud/seed/nocloud/`
- Ensures cloud-init processes the configuration on first boot

### Package Installation
- Installs essential packages for Ansible compatibility
- Includes development tools and utilities
- Configures system for cluster deployment

## Usage

### Step 1: Prepare VM Image

1. **Create Jenkins Job**:
   - Create a new pipeline job in Jenkins
   - Use `Jenkinsfile-image-prep` as the pipeline script
   - Configure the job to run on a Linux agent

2. **Configure Parameters**:
   - `SSH_PUBLIC_KEY`: Your SSH public key
   - `NETWORK_CONFIG_TYPE`: `dhcp` or `static`
   - `STATIC_IP`: IP address (if using static)
   - `GATEWAY`: Gateway IP (if using static)
   - `DNS_SERVERS`: DNS servers (comma-separated)
   - `IMAGE_NAME`: Name for the prepared image

3. **Run the Pipeline**:
   - Execute the pipeline
   - Wait for image preparation to complete
   - The prepared image will be saved to `/opt/hyperv/prepared-images/`

### Step 2: Deploy VMs

1. **Create Jenkins Job**:
   - Create a new pipeline job in Jenkins
   - Use `Jenkinsfile-deploy` as the pipeline script
   - Configure the job to run on a Windows Hyper-V agent

2. **Configure Parameters**:
   - `PREPARED_IMAGE_NAME`: Name of the prepared image
   - `DEPLOYMENT_TYPE`: `full`, `infrastructure`, `configuration`, or `workloads`
   - `DESTROY_EXISTING`: Whether to destroy existing VMs
   - IP address ranges for Consul and Nomad servers/clients

3. **Run the Pipeline**:
   - Execute the pipeline
   - VMs will be created and started automatically
   - Wait for networking configuration to complete

### Step 3: Configure Cluster

1. **Test SSH Connectivity**:
   ```bash
   ssh ubuntu@192.168.1.100
   ssh ubuntu@192.168.1.101
   # ... test all VMs
   ```

2. **Run Ansible Playbooks**:
   ```bash
   cd config/ansible
   ansible-playbook -i inventories/dev/hosts.yaml playbooks/consul.yml
   ansible-playbook -i inventories/dev/hosts.yaml playbooks/nomad.yml
   ```

## Manual Usage

### Using the Shell Script

You can also use the shell script directly:

```bash
# Make the script executable
chmod +x infra/scripts/prepare-vm-image.sh

# Run with parameters
./infra/scripts/prepare-vm-image.sh \
  --ssh-key "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ..." \
  --network static \
  --ip 192.168.1.100 \
  --gateway 192.168.1.1 \
  --dns "8.8.8.8,8.8.4.4" \
  --output "my-prepared-image"
```

### Using the PowerShell Script

For Windows deployment:

```powershell
# Run the deployment script
.\infra\scripts\deploy-from-prepared-image.ps1 \
  -PreparedImagePath "C:\Hyper-V\PreparedImages\ubuntu-nomad-consul-prepared.vhd" \
  -DestroyExisting
```

## File Structure

```
ci/
├── Jenkinsfile-image-prep    # Image preparation pipeline
├── Jenkinsfile-deploy        # Deployment pipeline
└── Jenkinsfile              # Original pipeline (for reference)

infra/scripts/
├── prepare-vm-image.sh      # Linux script for image preparation
├── deploy-from-prepared-image.ps1  # Windows script for deployment
├── create-test-vm.ps1       # Test VM creation script
└── destroy-hyperv-vms-simple.ps1  # VM destruction script

docs/
└── VM-Image-Preparation-Pipeline.md  # This documentation
```

## Technical Details

### VHD Mounting Process
1. Convert VHD to raw format using `qemu-img`
2. Find partition offset using `fdisk`
3. Mount partition with calculated offset
4. Inject cloud-init files
5. Unmount and convert back to VHD

### Cloud-Init Configuration
- **user-data**: User configuration, SSH keys, packages, run commands
- **network-config**: Network interface configuration
- **meta-data**: Instance metadata

### Security Considerations
- SSH keys are injected securely
- Password authentication is enabled as fallback
- Proper file permissions are set
- Cloud-init files are placed in standard locations

## Troubleshooting

### Common Issues

1. **VHD Mounting Fails**:
   - Ensure `qemu-utils` and `kpartx` are installed
   - Check if the VHD file is corrupted
   - Verify partition offset calculation

2. **Cloud-Init Not Working**:
   - Check file permissions on cloud-init files
   - Verify files are in correct locations
   - Check cloud-init logs in the VM

3. **Networking Issues**:
   - Verify network configuration syntax
   - Check if DHCP is working on the network
   - Test with static IP configuration

4. **SSH Access Issues**:
   - Verify SSH key format
   - Check SSH server configuration
   - Test with password authentication

### Logs and Debugging

- **Jenkins Pipeline Logs**: Check Jenkins console output
- **VM Console**: Use Hyper-V console to check VM boot process
- **Cloud-Init Logs**: Check `/var/log/cloud-init.log` in the VM
- **SSH Logs**: Check `/var/log/auth.log` in the VM

## Benefits

1. **Automated Setup**: No manual configuration required
2. **Consistent Images**: All VMs start with identical configuration
3. **Fast Deployment**: Pre-configured images boot quickly
4. **Ansible Ready**: VMs are immediately ready for Ansible configuration
5. **Reproducible**: Same process every time
6. **Scalable**: Easy to create multiple VMs with different configurations

## Future Enhancements

1. **Azure Integration**: Upload prepared images to Azure storage
2. **Image Versioning**: Track different versions of prepared images
3. **Custom Packages**: Allow injection of custom packages
4. **Multi-OS Support**: Support for other operating systems
5. **Image Validation**: Automated testing of prepared images
