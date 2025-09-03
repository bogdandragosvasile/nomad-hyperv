#!/bin/bash

# Jenkins CLI Plugin Installation Script
# This script uses Jenkins CLI to install plugins directly

JENKINS_URL="http://localhost:8080"
JENKINS_JAR="jenkins-cli.jar"
ADMIN_USER="admin"
ADMIN_PASS="admin"

# Download Jenkins CLI
download_cli() {
    echo "📥 Downloading Jenkins CLI..."
    if [ ! -f "$JENKINS_JAR" ]; then
        curl -o "$JENKINS_JAR" "$JENKINS_URL/jnlpJars/jenkins-cli.jar"
        echo "✅ Jenkins CLI downloaded"
    else
        echo "✅ Jenkins CLI already exists"
    fi
}

# Install plugin using CLI
install_plugin_cli() {
    local plugin_name="$1"
    echo "🔌 Installing plugin: $plugin_name"
    
    java -jar "$JENKINS_JAR" -s "$JENKINS_URL" -auth "$ADMIN_USER:$ADMIN_PASS" install-plugin "$plugin_name" -deploy
    
    if [ $? -eq 0 ]; then
        echo "✅ Plugin $plugin_name installed successfully"
    else
        echo "❌ Failed to install plugin $plugin_name"
    fi
}

# Main installation function
main() {
    echo "🚀 Starting Jenkins Plugin Installation via CLI"
    echo "================================================"
    
    # Check if Jenkins is accessible
    if ! curl -s "$JENKINS_URL/api/json" > /dev/null; then
        echo "❌ Jenkins is not accessible at $JENKINS_URL"
        echo "Please ensure Jenkins is running and accessible"
        exit 1
    fi
    
    # Download CLI
    download_cli
    
    # List of essential plugins to install
    PLUGINS=(
        "terraform-plugin"
        "ansible-plugin"
        "docker-plugin"
        "kubernetes-plugin"
        "prometheus-plugin"
        "blueocean"
        "pipeline-utility-steps"
    )
    
    echo ""
    echo "📦 Installing ${#PLUGINS[@]} essential plugins via CLI..."
    echo "================================================"
    
    SUCCESS_COUNT=0
    FAILED_COUNT=0
    
    for plugin in "${PLUGINS[@]}"; do
        if install_plugin_cli "$plugin"; then
            ((SUCCESS_COUNT++))
        else
            ((FAILED_COUNT++))
        fi
        echo ""
    done
    
    echo "================================================"
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
    fi
    
    echo ""
    echo "🔗 Jenkins URL: $JENKINS_URL"
    echo "👤 Admin User: $ADMIN_USER"
    echo "🔑 Admin Password: $ADMIN_PASS"
}

# Run main function
main "$@"
