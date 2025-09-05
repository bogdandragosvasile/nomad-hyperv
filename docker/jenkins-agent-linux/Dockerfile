FROM jenkins/inbound-agent:latest

# Switch to root to install packages
USER root

# Install required packages for VHD manipulation
RUN apt-get update && \
    apt-get install -y \
    qemu-utils \
    kpartx \
    cloud-guest-utils \
    file \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create jenkins user with sudo access
RUN echo "jenkins ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch back to jenkins user
USER jenkins
