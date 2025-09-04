#!/bin/bash

echo "Jenkins Agent with IaC tools ready"
echo "Available tools:"
echo "  - Terraform: $(terraform version)"
echo "  - Ansible: $(ansible --version | head -1)"
echo "  - Nomad: $(nomad version)"
echo "  - Consul: $(consul version)"
echo "  - Docker: $(docker --version)"
echo "  - kubectl: $(kubectl version --client)"
echo "Starting agent connection to Jenkins..."

# Download agent.jar if it doesn't exist
if [ ! -f "/home/jenkins/workspace/agent.jar" ]; then
    echo "Downloading agent.jar..."
    curl -o /home/jenkins/workspace/agent.jar http://jenkins:8080/jnlpJars/agent.jar
fi

# Connect to Jenkins
echo "Connecting to Jenkins master..."
java -jar /home/jenkins/workspace/agent.jar \
    -url http://jenkins:8080/ \
    -secret edde47c76c5c04405fc18c65b4cad82c39afe00cb0a3fb6f779bd8dafd5faa1b \
    -name "nomad-consul-agent" \
    -webSocket \
    -workDir "/home/jenkins/workspace"

