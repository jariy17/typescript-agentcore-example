#!/bin/bash

# Deploy script for my-agent-service
# Usage: ./deploy.sh [runtime-id] [bedrock-agentcore-path]
# 
# Arguments:
#   runtime-id - Required: The agent runtime ID
#   bedrock-agentcore-path - Optional: Path to bedrock-agentcore package (default: ../bedrock-agentcore-sdk-typescript-private)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting deployment process...${NC}"

# Check if runtime ID is provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Runtime ID required${NC}"
    echo "Usage: ./deploy.sh my-agent-service-XXXXXXXXXX [bedrock-agentcore-path]"
    exit 1
fi

RUNTIME_ID="$1"

# Get bedrock-agentcore path from second argument or use default
BEDROCK_AGENTCORE_PATH="${2:-../bedrock-agentcore-sdk-typescript-private}"

# Step 1: Lint and format code
echo -e "${YELLOW}🔍 Linting and formatting code...${NC}"
npm run check

# Step 2: Build TypeScript
echo -e "${YELLOW}📦 Building TypeScript...${NC}"
npm run build

# Step 3: Set Environment Variables
echo -e "${YELLOW}🔧 Setting up environment variables...${NC}"
export ACCOUNTID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-west-2
export ECR_REPO=my-agent-service

echo "Account ID: $ACCOUNTID"
echo "Region: $AWS_REGION"
echo "ECR Repo: $ECR_REPO"
echo "SDK File Path $BEDROCK_AGENTCORE_PATH"
echo "

# Step 4: Get IAM Role ARN
echo -e "${YELLOW}🔑 Getting IAM Role ARN...${NC}"
export ROLE_ARN=$(aws iam get-role --role-name BedrockAgentCoreRuntimeRole --query 'Role.Arn' --output text)
echo "Role ARN: $ROLE_ARN"

# Step 5: Create ECR Repository (if it doesn't exist)
echo -e "${YELLOW}📦 Ensuring ECR repository exists...${NC}"
aws ecr describe-repositories --repository-names ${ECR_REPO} --region ${AWS_REGION} 2>/dev/null || {
    echo "Creating ECR repository: ${ECR_REPO}"
    aws ecr create-repository --repository-name ${ECR_REPO} --region ${AWS_REGION}
}

# Step 6: Build Docker Image
echo -e "${YELLOW}🐳 Building Docker image...${NC}"

# Use the build-docker.sh script with the bedrock-agentcore path
bash build-docker.sh "$BEDROCK_AGENTCORE_PATH"

# Tag the image for ECR
docker tag my-agent-service ${ACCOUNTID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest

# Step 7: Push to ECR
echo -e "${YELLOW}📤 Pushing to ECR...${NC}"
# Login to ECR first
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ACCOUNTID}.dkr.ecr.${AWS_REGION}.amazonaws.com

docker push ${ACCOUNTID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest

# Step 8: Update Runtime
echo -e "${YELLOW}🔄 Updating agent runtime...${NC}"
aws bedrock-agentcore-control update-agent-runtime \
  --agent-runtime-id "${RUNTIME_ID}" \
  --agent-runtime-artifact "{\"containerConfiguration\": {\"containerUri\": \"${ACCOUNTID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest\"}}" \
  --role-arn "${ROLE_ARN}" \
  --network-configuration "{\"networkMode\": \"PUBLIC\"}" \
  --protocol-configuration serverProtocol=HTTP \
  --region ${AWS_REGION}

echo -e "${GREEN}✅ Deployment complete!${NC}"
echo -e "${YELLOW}⏳ Wait about 1 minute for the update to complete, then test with:${NC}"
echo "npm run invoke"