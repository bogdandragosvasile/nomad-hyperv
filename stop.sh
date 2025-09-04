#!/bin/bash

# Stop Jenkins Environment Script
# This script gracefully stops the Jenkins environment

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

# Stop Jenkins environment
stop_jenkins() {
    log_info "Stopping Jenkins environment..."
    
    cd ci/jenkins-bootstrap
    
    # Stop all services
    log_info "Stopping Docker Compose services..."
    docker-compose down
    
    # Remove any remaining containers
    log_info "Cleaning up remaining containers..."
    docker ps -a --filter "name=nomad-consul" --format "table {{.Names}}" | grep -v NAMES | xargs -r docker rm -f
    
    # Remove networks
    log_info "Cleaning up networks..."
    docker network ls --filter "name=jenkins-bootstrap" --format "{{.Name}}" | xargs -r docker network rm
    
    cd ../..
    
    log_success "Jenkins environment stopped successfully!"
}

# Stop any running Java processes (Windows agents)
stop_java_processes() {
    log_info "Checking for running Java processes..."
    
    # Check if we're on Windows (Git Bash)
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        log_info "Stopping any running Java processes (Windows agents)..."
        powershell -Command "Get-Process java -ErrorAction SilentlyContinue | Stop-Process -Force" 2>/dev/null || true
    fi
}

# Display final status
show_status() {
    log_info "Final status check..."
    
    # Check if any containers are still running
    running_containers=$(docker ps --filter "name=nomad-consul" --format "{{.Names}}" | wc -l)
    
    if [ "$running_containers" -eq 0 ]; then
        log_success "All Jenkins containers stopped successfully!"
    else
        log_warning "Some containers may still be running:"
        docker ps --filter "name=nomad-consul"
    fi
    
    echo ""
    echo "🛑 Jenkins Environment Stopped"
    echo "=============================="
    echo ""
    echo "📊 Status:"
    docker ps -a --filter "name=nomad-consul" || echo "No Jenkins containers found"
    echo ""
    echo "📝 To start again:"
    echo "  ./bootstrap.sh"
    echo ""
}

# Main execution
main() {
    echo "🛑 Stopping Nomad + Consul Jenkins Environment"
    echo "=============================================="
    echo ""
    
    stop_jenkins
    stop_java_processes
    show_status
    
    echo ""
    log_success "Stop completed successfully! 🎉"
}

# Run main function
main "$@"
