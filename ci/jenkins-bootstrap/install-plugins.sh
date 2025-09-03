#!/bin/bash

# Jenkins Plugin Installation Script for Nomad + Consul Pipeline
# Run this script to install all required plugins

JENKINS_URL="http://localhost:8080"
ADMIN_USER="admin"
ADMIN_PASS="admin"

# Get CSRF token
get_crumb() {
    curl -s "$JENKINS_URL/crumbIssuer/api/json" | jq -r '.crumb'
}

# Install plugin
install_plugin() {
    local plugin_name="$1"
    local crumb="$2"
    
    echo "Installing plugin: $plugin_name"
    
    # Check if plugin is already installed
    if curl -s "$JENKINS_URL/pluginManager/api/json?depth=1" | jq -r '.plugins[].shortName' | grep -q "^${plugin_name}$"; then
        echo "✅ Plugin $plugin_name is already installed"
        return 0
    fi
    
    # Install plugin
    local response=$(curl -s -w "%{http_code}" -X POST \
        "$JENKINS_URL/pluginManager/installNecessaryPlugins" \
        -H "Jenkins-Crumb: $crumb" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "plugin=$plugin_name")
    
    local status_code="${response: -3}"
    local response_body="${response%???}"
    
    if [ "$status_code" = "200" ]; then
        echo "✅ Plugin $plugin_name installed successfully"
        return 0
    else
        echo "❌ Failed to install plugin $plugin_name (Status: $status_code)"
        echo "Response: $response_body"
        return 1
    fi
}

# Main installation function
main() {
    echo "🚀 Starting Jenkins Plugin Installation for Nomad + Consul Pipeline"
    echo "================================================================"
    
    # Check if Jenkins is accessible
    if ! curl -s "$JENKINS_URL/api/json" > /dev/null; then
        echo "❌ Jenkins is not accessible at $JENKINS_URL"
        echo "Please ensure Jenkins is running and accessible"
        exit 1
    fi
    
    # Get CSRF token
    echo "🔐 Getting CSRF token..."
    CRUMB=$(get_crumb)
    if [ -z "$CRUMB" ]; then
        echo "❌ Failed to get CSRF token"
        exit 1
    fi
    echo "✅ CSRF token obtained: ${CRUMB:0:20}..."
    
    # List of essential plugins to install
    PLUGINS=(
        # Infrastructure & Cloud
        "terraform-plugin"
        "ansible-plugin"
        "docker-plugin"
        "kubernetes-plugin"
        
        # Monitoring & Observability
        "prometheus-plugin"
        "monitoring-plugin"
        
        # Security & Credentials
        "hashicorp-vault-plugin"
        "aws-credentials"
        
        # Notifications
        "email-ext-plugin"
        "slack-plugin"
        "webhook-plugin"
        
        # Code Quality
        "sonarqube-plugin"
        "junit-plugin"
        "cobertura-plugin"
        
        # Backup & Recovery
        "thinbackup-plugin"
        
        # Advanced Pipeline
        "pipeline-utility-steps"
        "pipeline-aws"
        
        # UI & UX
        "blueocean"
        "simple-theme-plugin"
    )
    
    echo ""
    echo "📦 Installing ${#PLUGINS[@]} essential plugins..."
    echo "================================================================"
    
    SUCCESS_COUNT=0
    FAILED_COUNT=0
    
    for plugin in "${PLUGINS[@]}"; do
        if install_plugin "$plugin" "$CRUMB"; then
            ((SUCCESS_COUNT++))
        else
            ((FAILED_COUNT++))
        fi
        echo ""
    done
    
    echo "================================================================"
    echo "📊 Installation Summary:"
    echo "✅ Successfully installed: $SUCCESS_COUNT plugins"
    echo "❌ Failed to install: $FAILED_COUNT plugins"
    
    if [ $FAILED_COUNT -eq 0 ]; then
        echo ""
        echo "🎉 All plugins installed successfully!"
        echo "🔄 Please restart Jenkins to complete the installation"
        echo "   Go to: Manage Jenkins → Restart Jenkins"
    else
        echo ""
        echo "⚠️  Some plugins failed to install. Check the logs above for details."
        echo "🔄 You may need to restart Jenkins and try again for failed plugins."
    fi
    
    echo ""
    echo "🔗 Jenkins URL: $JENKINS_URL"
    echo "👤 Admin User: $ADMIN_USER"
    echo "🔑 Admin Password: $ADMIN_PASS"
}

# Run main function
main "$@"
