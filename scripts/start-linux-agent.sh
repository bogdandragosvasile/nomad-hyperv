#!/bin/bash

# Start Jenkins Linux agent with all prerequisites
echo "🚀 Starting Jenkins Linux agent with VHD manipulation tools..."

# Navigate to the docker directory
cd "$(dirname "$0")/../docker/jenkins-agent-linux"

# Create Jenkins network if it doesn't exist
echo "📡 Creating Jenkins network..."
docker network create jenkins 2>/dev/null || echo "Jenkins network already exists"

# Build and start the agent
echo "🔨 Building and starting Jenkins Linux agent..."
docker-compose up --build -d

# Wait a moment for the agent to start
sleep 5

# Check if the agent is running
echo "✅ Checking agent status..."
if docker-compose ps | grep -q "Up"; then
    echo "🎉 Jenkins Linux agent started successfully!"
    echo "📋 Agent details:"
    echo "   - Name: linux-vm-prep-agent"
    echo "   - Status: $(docker-compose ps --services --filter status=running)"
    echo ""
    echo "🔍 Useful commands:"
    echo "   - Check status: docker-compose ps"
    echo "   - View logs: docker-compose logs -f"
    echo "   - Stop agent: docker-compose down"
    echo ""
    echo "🎯 The agent is now ready for VM image preparation!"
else
    echo "❌ Failed to start Jenkins Linux agent"
    echo "📋 Check logs with: docker-compose logs"
    exit 1
fi
