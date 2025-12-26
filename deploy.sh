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
    echo -e "${RED}Usage: ./deploy.sh my-agent-service-XXXXXXXXXX [bedrock-agentcore-path]${NC}"
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

# Link bedrock-agentcore package locally for build
echo -e "${CYAN}Linking bedrock-agentcore package locally...${NC}"
(cd "$BEDROCK_AGENTCORE_PATH" && npm install && npm run build && npm link)
npm link bedrock-agentcore

npm run build

# Step 3: Set Environment Variables
echo -e "${YELLOW}🔧 Setting up environment variables...${NC}"
export ACCOUNTID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-west-2
export ECR_REPO=$(echo "${RUNTIME_ID}-repo" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g')

echo -e "${CYAN}Account ID: $ACCOUNTID${NC}"
echo -e "${CYAN}Region: $AWS_REGION${NC}"
echo -e "${CYAN}ECR Repo: $ECR_REPO${NC}"
echo -e "${CYAN}SDK File Path $BEDROCK_AGENTCORE_PATH${NC}"

# Step 4: Get IAM Role ARN
echo -e "${YELLOW}🔑 Getting IAM Role ARN...${NC}"
export ROLE_ARN=$(bash create-iam-role.sh)
echo -e "${CYAN}Role ARN: $ROLE_ARN${NC}"

# Step 5: Create ECR Repository (if it doesn't exist)
echo -e "${YELLOW}📦 Ensuring ECR repository exists...${NC}"
aws ecr describe-repositories --repository-names ${ECR_REPO} --region ${AWS_REGION} --no-cli-pager 2>/dev/null || {
    echo -e "${YELLOW}ECR repository '${ECR_REPO}' does not exist.${NC}"
    echo -e "${CYAN}Do you want to create it? (y/N): ${NC}"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Creating ECR repository: ${ECR_REPO}${NC}"
        aws ecr create-repository --repository-name ${ECR_REPO} --region ${AWS_REGION}
    else
        echo -e "${RED}❌ ECR repository creation cancelled. Stopping deployment.${NC}"
        exit 1
    fi
}

# Step 6: Build Docker Image
echo -e "${YELLOW}🐳 Building Docker image...${NC}"

# Use the build-docker.sh script
if ! bash build-docker.sh "$BEDROCK_AGENTCORE_PATH"; then
    echo -e "${RED}❌ Docker build failed. Stopping deployment.${NC}"
    exit 1
fi

# Tag the image for ECR
docker tag my-agent-service ${ACCOUNTID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest

# Step 7: Push to ECR
echo -e "${YELLOW}📤 Pushing to ECR...${NC}"
# Login to ECR first
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ACCOUNTID}.dkr.ecr.${AWS_REGION}.amazonaws.com

docker push ${ACCOUNTID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest

# Step 8: Create or Update Runtime
echo -e "${YELLOW}🔄 Checking agent runtime...${NC}"

# Check if runtime exists by ID
echo -e "${CYAN}Checking if runtime ${RUNTIME_ID} exists...${NC}"
if aws bedrock-agentcore-control get-agent-runtime --agent-runtime-id "${RUNTIME_ID}" --region ${AWS_REGION} --no-cli-pager 2>/dev/null 2>&1; then
    echo -e "${GREEN}Runtime exists - updating...${NC}"
    aws bedrock-agentcore-control update-agent-runtime \
      --agent-runtime-id "${RUNTIME_ID}" \
      --agent-runtime-artifact "{\"containerConfiguration\": {\"containerUri\": \"${ACCOUNTID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest\"}}" \
      --role-arn "${ROLE_ARN}" \
      --network-configuration "{\"networkMode\": \"PUBLIC\"}" \
      --protocol-configuration serverProtocol=HTTP \
      --region ${AWS_REGION} \
      --no-cli-pager
else
    echo -e "${YELLOW}Agent runtime '${RUNTIME_ID}' does not exist.${NC}"
    echo -e "${CYAN}Do you want to create it? (y/N): ${NC}"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Creating new agent runtime...${NC}"
        aws bedrock-agentcore-control create-agent-runtime \
          --agent-runtime-name my_agent_service \
          --agent-runtime-artifact containerConfiguration={containerUri=${ACCOUNTID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest} \
          --role-arn ${ROLE_ARN} \
          --network-configuration networkMode=PUBLIC \
          --protocol-configuration serverProtocol=HTTP \
          --region ${AWS_REGION}
    else
        echo -e "${RED}❌ Agent runtime creation cancelled. Stopping deployment.${NC}"
        exit 1
    fi \
fi

echo -e "${GREEN}✅ Deployment complete!${NC}"
echo -e "${YELLOW}⏳ Wait about 1 minute for the update to complete, then test with:${NC}"
echo -e "${CYAN}npm run invoke -- arn:aws:bedrock-agentcore:${AWS_REGION}:${ACCOUNTID}:runtime/${RUNTIME_ID}${NC}"