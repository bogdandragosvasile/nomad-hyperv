#!/bin/bash

# Nomad + Consul Jenkins Environment Bootstrap Script
# This script automates the complete setup of the Jenkins environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Windows
check_os() {
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        log_error "This script is for Linux/macOS. Use bootstrap.ps1 for Windows."
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    log_success "All prerequisites met!"
}

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."
    
    mkdir -p ci/jenkins-bootstrap/nginx/conf.d
    mkdir -p ci/jenkins-bootstrap/nginx/ssl
    mkdir -p ~/.ssh
    mkdir -p logs
    
    log_success "Directories created!"
}

# Generate SSH keys if they don't exist
setup_ssh_keys() {
    log_info "Setting up SSH keys..."
    
    if [[ ! -f ~/.ssh/id_rsa ]]; then
        log_info "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "jenkins-agent@nomad-consul"
        log_success "SSH key pair generated!"
    else
        log_info "SSH key pair already exists, skipping generation."
    fi
    
    # Display public key for manual addition to VMs
    log_info "SSH Public Key (add this to your VMs for Ansible access):"
    echo "----------------------------------------"
    cat ~/.ssh/id_rsa.pub
    echo "----------------------------------------"
}

# Create nginx configuration
create_nginx_config() {
    log_info "Creating nginx configuration..."
    
    cat > ci/jenkins-bootstrap/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    include /etc/nginx/conf.d/*.conf;
}
EOF

    cat > ci/jenkins-bootstrap/nginx/conf.d/jenkins.conf << 'EOF'
upstream jenkins {
    server jenkins:8080;
}

server {
    listen 80;
    server_name localhost;
    
    location / {
        proxy_pass http://jenkins;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

    log_success "Nginx configuration created!"
}

# Start Jenkins environment
start_jenkins() {
    log_info "Starting Jenkins environment..."
    
    cd ci/jenkins-bootstrap
    
    # Start Jenkins master
    log_info "Starting Jenkins master..."
    docker-compose up -d jenkins
    
    # Wait for Jenkins to be ready
    log_info "Waiting for Jenkins to be ready..."
    timeout=300
    counter=0
    while ! curl -f http://localhost:8080/login &> /dev/null; do
        if [ $counter -ge $timeout ]; then
            log_error "Jenkins failed to start within $timeout seconds"
            exit 1
        fi
        sleep 5
        counter=$((counter + 5))
        log_info "Waiting for Jenkins... ($counter/$timeout seconds)"
    done
    
    log_success "Jenkins is ready!"
    
    # Start agent
    log_info "Starting Jenkins agent..."
    docker-compose --profile agent up -d jenkins-agent
    
    # Wait for agent to connect
    log_info "Waiting for agent to connect..."
    sleep 10
    
    # Check agent status
    if curl -s http://localhost:8080/computer/nomad-consul-agent/api/json | grep -q '"offline":false'; then
        log_success "Jenkins agent connected successfully!"
    else
        log_warning "Agent connection status unclear. Check Jenkins UI."
    fi
    
    cd ../..
}

# Display status and access information
show_status() {
    log_success "Jenkins environment is ready!"
    echo ""
    echo "🌐 Access URLs:"
    echo "  Jenkins UI: http://localhost:8080"
    echo "  Jenkins via Nginx: http://localhost (if reverse proxy is enabled)"
    echo ""
    echo "🔑 Default Credentials:"
    echo "  Username: admin"
    echo "  Password: admin"
    echo ""
    echo "📊 Status:"
    docker-compose -f ci/jenkins-bootstrap/docker-compose.yml ps
    echo ""
    echo "📝 Useful Commands:"
    echo "  Stop: ./stop.sh"
    echo "  Restart: ./restart.sh"
    echo "  Logs: docker-compose -f ci/jenkins-bootstrap/docker-compose.yml logs -f"
    echo "  Agent Logs: docker-compose -f ci/jenkins-bootstrap/docker-compose.yml logs -f jenkins-agent"
}

# Main execution
main() {
    echo "🚀 Nomad + Consul Jenkins Environment Bootstrap"
    echo "================================================"
    echo ""
    
    check_os
    check_prerequisites
    create_directories
    setup_ssh_keys
    create_nginx_config
    start_jenkins
    show_status
    
    echo ""
    log_success "Bootstrap completed successfully! 🎉"
}

# Run main function
main "$@"
