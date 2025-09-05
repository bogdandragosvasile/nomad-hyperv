#!/bin/bash

# Script to prepare VM image with cloud-init configuration
# This script can be used standalone or as part of the Jenkins pipeline

set -e

# Configuration
VHD_BASE_PATH="/opt/hyperv/vhds"
PREPARED_IMAGE_PATH="/opt/hyperv/prepared-images"
WORKSPACE_PATH="/tmp/vm-image-prep"
BASE_IMAGE_NAME="livecd.ubuntu-cpc.azure.vhd"
PREPARED_IMAGE_NAME="ubuntu-nomad-consul-prepared"

# Default parameters
SSH_PUBLIC_KEY=""
NETWORK_CONFIG_TYPE="dhcp"
STATIC_IP="192.168.1.100"
GATEWAY="192.168.1.1"
DNS_SERVERS="8.8.8.8,8.8.4.4"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -k, --ssh-key KEY        SSH public key to inject"
    echo "  -n, --network TYPE       Network config type (dhcp|static)"
    echo "  -i, --ip IP              Static IP address (if using static)"
    echo "  -g, --gateway GATEWAY    Gateway IP address (if using static)"
    echo "  -d, --dns DNS            DNS servers (comma-separated)"
    echo "  -o, --output NAME        Output image name"
    echo "  -h, --help               Show this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -k|--ssh-key)
            SSH_PUBLIC_KEY="$2"
            shift 2
            ;;
        -n|--network)
            NETWORK_CONFIG_TYPE="$2"
            shift 2
            ;;
        -i|--ip)
            STATIC_IP="$2"
            shift 2
            ;;
        -g|--gateway)
            GATEWAY="$2"
            shift 2
            ;;
        -d|--dns)
            DNS_SERVERS="$2"
            shift 2
            ;;
        -o|--output)
            PREPARED_IMAGE_NAME="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [ -z "$SSH_PUBLIC_KEY" ]; then
    echo "Error: SSH public key is required"
    usage
fi

echo "=== VM Image Preparation ==="
echo "SSH Key: ${SSH_PUBLIC_KEY:0:50}..."
echo "Network Type: $NETWORK_CONFIG_TYPE"
echo "Output Image: $PREPARED_IMAGE_NAME"
echo ""

# Create necessary directories
echo "Creating directories..."
sudo mkdir -p "$VHD_BASE_PATH"
sudo mkdir -p "$PREPARED_IMAGE_PATH"
mkdir -p "$WORKSPACE_PATH"

# Set permissions
sudo chown -R $(whoami):$(whoami) "$VHD_BASE_PATH"
sudo chown -R $(whoami):$(whoami) "$PREPARED_IMAGE_PATH"

# Install required packages
echo "Installing required packages..."
sudo apt-get update
sudo apt-get install -y qemu-utils kpartx cloud-guest-utils

# Check if base image exists
BASE_IMAGE_PATH="$VHD_BASE_PATH/$BASE_IMAGE_NAME"
if [ ! -f "$BASE_IMAGE_PATH" ]; then
    echo "Base image not found. Please download it first."
    echo "Expected location: $BASE_IMAGE_PATH"
    exit 1
fi

# Create working copy
echo "Creating working copy of VHD..."
cd "$WORKSPACE_PATH"
cp "$BASE_IMAGE_PATH" "./working-image.vhd"

# Convert VHD to raw format
echo "Converting VHD to raw format..."
qemu-img convert -f vpc -O raw working-image.vhd working-image.raw

# Create mount points
mkdir -p mount-point

# Find partition offset
echo "Finding partition offset..."
PARTITION_OFFSET=$(fdisk -l working-image.raw | grep "Linux filesystem" | awk '{print $2}')
if [ -z "$PARTITION_OFFSET" ]; then
    echo "Error: Could not find partition offset"
    exit 1
fi

# Calculate offset in bytes
OFFSET_BYTES=$((PARTITION_OFFSET * 512))
echo "Partition offset: $PARTITION_OFFSET sectors ($OFFSET_BYTES bytes)"

# Mount the partition
echo "Mounting partition..."
sudo mount -o loop,offset=$OFFSET_BYTES working-image.raw mount-point

# Verify mount
echo "Verifying mount..."
ls -la mount-point/

# Create cloud-init directory structure
echo "Creating cloud-init directory structure..."
sudo mkdir -p mount-point/var/lib/cloud/seed/nocloud-net
sudo mkdir -p mount-point/var/lib/cloud/seed/nocloud

# Create user-data
echo "Creating user-data..."
cat > user-data << EOF
#cloud-config
hostname: ubuntu-nomad-consul
fqdn: ubuntu-nomad-consul.local
manage_etc_hosts: true

users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - $SSH_PUBLIC_KEY
    lock_passwd: false
    passwd: \$6\$rounds=4096\$salt\$hash
    groups: [adm, audio, cdrom, dialout, dip, floppy, lxd, netdev, plugdev, sudo, video]

ssh_pwauth: true

package_update: true
package_upgrade: true

packages:
  - openssh-server
  - curl
  - wget
  - unzip
  - python3
  - python3-pip
  - python3-venv
  - git
  - htop
  - vim
  - net-tools
  - dnsutils
  - ca-certificates
  - gnupg
  - lsb-release
  - software-properties-common
  - apt-transport-https

write_files:
  - path: /etc/ssh/sshd_config.d/99-cloud-init.conf
    content: |
      PasswordAuthentication yes
      PubkeyAuthentication yes
      AuthorizedKeysFile .ssh/authorized_keys
      PermitRootLogin no
      MaxAuthTries 6
      ClientAliveInterval 60
      ClientAliveCountMax 3
    permissions: '0644'

runcmd:
  - systemctl enable ssh
  - systemctl restart ssh
  - ufw allow ssh
  - ufw --force enable
  - echo "VM is ready with cloud-init configuration" > /var/log/vm-ready.log
  - systemctl restart networking

final_message: "VM is ready with cloud-init configuration"
EOF

# Create network-config
echo "Creating network-config..."
if [ "$NETWORK_CONFIG_TYPE" = "static" ]; then
    # Convert DNS servers to YAML format
    DNS_YAML=""
    IFS=',' read -ra DNS_ARRAY <<< "$DNS_SERVERS"
    for dns in "${DNS_ARRAY[@]}"; do
        DNS_YAML="${DNS_YAML}          - ${dns// /}\n"
    done
    
    cat > network-config << EOF
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      dhcp6: false
      addresses:
        - $STATIC_IP/24
      gateway4: $GATEWAY
      nameservers:
        addresses:
$(echo -e "$DNS_YAML")
EOF
else
    cat > network-config << EOF
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
      dhcp6: false
EOF
fi

# Create meta-data
echo "Creating meta-data..."
cat > meta-data << EOF
instance-id: ubuntu-nomad-consul
local-hostname: ubuntu-nomad-consul
public-keys:
  - jenkins@nomad-consul
EOF

# Copy cloud-init files to mounted image
echo "Copying cloud-init files to mounted image..."
sudo cp user-data mount-point/var/lib/cloud/seed/nocloud-net/user-data
sudo cp user-data mount-point/var/lib/cloud/seed/nocloud/user-data
sudo cp network-config mount-point/var/lib/cloud/seed/nocloud-net/network-config
sudo cp network-config mount-point/var/lib/cloud/seed/nocloud/network-config
sudo cp meta-data mount-point/var/lib/cloud/seed/nocloud-net/meta-data
sudo cp meta-data mount-point/var/lib/cloud/seed/nocloud/meta-data

# Set proper permissions
sudo chmod 644 mount-point/var/lib/cloud/seed/nocloud-net/*
sudo chmod 644 mount-point/var/lib/cloud/seed/nocloud/*

# Verify files
echo "Verifying cloud-init files..."
ls -la mount-point/var/lib/cloud/seed/nocloud-net/
ls -la mount-point/var/lib/cloud/seed/nocloud/

# Unmount the partition
echo "Unmounting partition..."
sudo umount mount-point

# Convert back to VHD format
echo "Converting back to VHD format..."
qemu-img convert -f raw -O vpc working-image.raw "${PREPARED_IMAGE_NAME}.vhd"

# Copy to prepared images directory
echo "Copying prepared image..."
cp "${PREPARED_IMAGE_NAME}.vhd" "$PREPARED_IMAGE_PATH/"

# Verify the prepared image
echo "Verifying prepared image..."
ls -la "$PREPARED_IMAGE_PATH/${PREPARED_IMAGE_NAME}.vhd"
file "$PREPARED_IMAGE_PATH/${PREPARED_IMAGE_NAME}.vhd"

# Clean up
echo "Cleaning up..."
rm -f working-image.vhd working-image.raw
rm -f user-data network-config meta-data
rm -rf mount-point

echo ""
echo "✅ VM image preparation completed successfully!"
echo "Prepared image: $PREPARED_IMAGE_PATH/${PREPARED_IMAGE_NAME}.vhd"
echo ""
echo "The image is now ready for deployment with:"
echo "- SSH key injection: ✅"
echo "- Network configuration: ✅ ($NETWORK_CONFIG_TYPE)"
echo "- Cloud-init configuration: ✅"
echo ""
echo "You can now use this image to create VMs that will automatically:"
echo "1. Configure networking on first boot"
echo "2. Set up SSH access with the provided key"
echo "3. Install required packages"
echo "4. Be ready for Ansible configuration"
