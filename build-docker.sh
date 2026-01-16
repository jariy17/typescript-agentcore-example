#!/bin/bash

set -e  # Exit on any error

# Build Docker image script
# Usage: ./build-docker.sh

echo "Building Docker image..."

# Build the Docker image
if ! docker build -t my-agent-service .; then
    echo "Error: Docker build failed"
    exit 1
fi

echo "Docker build completed!"