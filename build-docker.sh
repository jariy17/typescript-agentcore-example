#!/bin/bash

# Build Docker image script
# Usage: ./build-docker.sh <bedrock-agentcore-path>

# Check if bedrock-agentcore path is provided
if [ -z "$1" ]; then
    echo "Error: bedrock-agentcore path is required"
    echo "Usage: ./build-docker.sh <bedrock-agentcore-path>"
    exit 1
fi

BEDROCK_AGENTCORE_PATH="$1"

echo "Building Docker image with bedrock-agentcore path: $BEDROCK_AGENTCORE_PATH"

# Check if the path exists
if [ ! -d "$BEDROCK_AGENTCORE_PATH" ]; then
    echo "Error: bedrock-agentcore directory not found at: $BEDROCK_AGENTCORE_PATH"
    echo "Usage: ./build-docker.sh <bedrock-agentcore-path>"
    exit 1
fi

# Build the Docker image with the build argument
docker build \
    --build-arg BEDROCK_AGENTCORE_PATH="$BEDROCK_AGENTCORE_PATH" \
    -t my-agent-service \
    .

echo "Docker build completed!"