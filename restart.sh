#!/bin/bash

# Restart Jenkins Environment Script
# This script stops and starts the Jenkins environment

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

# Main execution
main() {
    echo "🔄 Restarting Nomad + Consul Jenkins Environment"
    echo "================================================"
    echo ""
    
    # Stop first
    log_info "Stopping Jenkins environment..."
    ./stop.sh
    
    echo ""
    log_info "Waiting 5 seconds before restarting..."
    sleep 5
    
    echo ""
    # Start again
    log_info "Starting Jenkins environment..."
    ./bootstrap.sh
    
    echo ""
    log_success "Restart completed successfully! 🎉"
}

# Run main function
main "$@"
