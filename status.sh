#!/bin/bash

# Jenkins Environment Status Script
# This script shows the current status of the Jenkins environment

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

# Check Docker status
check_docker() {
    log_info "Checking Docker status..."
    
    if command -v docker &> /dev/null; then
        if docker info &> /dev/null; then
            log_success "Docker is running"
            docker --version
        else
            log_error "Docker is not running"
            return 1
        fi
    else
        log_error "Docker is not installed"
        return 1
    fi
}

# Check Jenkins containers
check_containers() {
    log_info "Checking Jenkins containers..."
    
    cd ci/jenkins-bootstrap
    
    echo ""
    echo "📊 Container Status:"
    echo "==================="
    docker-compose ps
    
    echo ""
    echo "📋 All Jenkins-related containers:"
    echo "=================================="
    docker ps -a --filter "name=nomad-consul" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    cd ../..
}

# Check Jenkins connectivity
check_jenkins_connectivity() {
    log_info "Checking Jenkins connectivity..."
    
    if curl -f http://localhost:8080/login &> /dev/null; then
        log_success "Jenkins is accessible at http://localhost:8080"
        
        # Check agent status
        if curl -s http://localhost:8080/computer/nomad-consul-agent/api/json | grep -q '"offline":false'; then
            log_success "Jenkins agent is online"
        else
            log_warning "Jenkins agent is offline"
        fi
    else
        log_error "Jenkins is not accessible at http://localhost:8080"
    fi
}

# Check networks
check_networks() {
    log_info "Checking Docker networks..."
    
    echo ""
    echo "🌐 Jenkins Networks:"
    echo "==================="
    docker network ls --filter "name=jenkins-bootstrap" --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"
}

# Check volumes
check_volumes() {
    log_info "Checking Docker volumes..."
    
    echo ""
    echo "💾 Jenkins Volumes:"
    echo "=================="
    docker volume ls --filter "name=jenkins-bootstrap" --format "table {{.Name}}\t{{.Driver}}"
}

# Check system resources
check_resources() {
    log_info "Checking system resources..."
    
    echo ""
    echo "💻 System Resources:"
    echo "==================="
    echo "CPU Usage:"
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | xargs -I {} echo "  {}%"
    
    echo "Memory Usage:"
    free -h | grep "Mem:" | awk '{print "  Used: " $3 " / " $2 " (" $3/$2*100 "%)"}'
    
    echo "Disk Usage:"
    df -h / | tail -1 | awk '{print "  Used: " $3 " / " $2 " (" $5 ")"}'
}

# Main execution
main() {
    echo "📊 Nomad + Consul Jenkins Environment Status"
    echo "============================================="
    echo ""
    
    # Check Docker first
    if ! check_docker; then
        log_error "Docker is not available. Cannot check Jenkins status."
        exit 1
    fi
    
    echo ""
    check_containers
    echo ""
    check_jenkins_connectivity
    echo ""
    check_networks
    echo ""
    check_volumes
    echo ""
    check_resources
    
    echo ""
    echo "🔗 Quick Access:"
    echo "==============="
    echo "  Jenkins UI: http://localhost:8080"
    echo "  Username: admin"
    echo "  Password: admin"
    echo ""
    echo "📝 Useful Commands:"
    echo "=================="
    echo "  Stop: ./stop.sh"
    echo "  Restart: ./restart.sh"
    echo "  Logs: docker-compose -f ci/jenkins-bootstrap/docker-compose.yml logs -f"
    echo "  Agent Logs: docker-compose -f ci/jenkins-bootstrap/docker-compose.yml logs -f jenkins-agent"
}

# Run main function
main "$@"
