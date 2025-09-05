#!/bin/bash

# Start Jenkins Linux agent with all prerequisites
echo "Starting Jenkins Linux agent with VHD manipulation tools..."

# Create Jenkins network if it doesn't exist
docker network create jenkins 2>/dev/null || true

# Build and start the agent
docker-compose up --build -d

echo "Jenkins Linux agent started successfully!"
echo "Agent name: linux-vm-prep-agent"
echo "Check status with: docker-compose ps"
echo "View logs with: docker-compose logs -f"
