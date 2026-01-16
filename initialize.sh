#!/bin/bash

# Initialize script for my-agent-service
# Usage: ./initialize.sh [runtime-name]
#
# Arguments:
#   runtime-name - Optional: Name for your agent runtime (default: my-agent-service)
#                  AWS will append a 10-character suffix to create the full runtime ID

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting initialization process...${NC}"

# Get runtime name from argument or use default
RUNTIME_NAME="${1:-my-agent-service}"

# Validate runtime name format: must start with letter, contain only letters, numbers, underscores
if ! [[ "$RUNTIME_NAME" =~ ^[a-zA-Z][a-zA-Z0-9_]{0,99}$ ]]; then
    echo -e "${RED}❌ Error: Invalid runtime name format${NC}"
    echo -e "${RED}Name must start with a letter and contain only letters, numbers, and underscores (max 100 chars)${NC}"
    echo -e "${YELLOW}Your name: ${RUNTIME_NAME}${NC}"
    exit 1
fi

echo -e "${CYAN}Runtime name: ${RUNTIME_NAME}${NC}"
echo -e "${YELLOW}Note: AWS will append a 10-character suffix to create the full runtime ID${NC}"

# Step 1: Build TypeScript
echo -e "${YELLOW}📦 Building TypeScript...${NC}"
npm run build

# Step 2: Set Environment Variables
echo -e "${YELLOW}🔧 Setting up environment variables...${NC}"
export ACCOUNTID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-west-2
export ECR_REPO=$(echo "${RUNTIME_NAME}-repo" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g')

echo -e "${CYAN}Account ID: $ACCOUNTID${NC}"
echo -e "${CYAN}Region: $AWS_REGION${NC}"
echo -e "${CYAN}ECR Repo: $ECR_REPO${NC}"

# Step 3: Get IAM Role ARN
echo -e "${YELLOW}🔑 Getting IAM Role ARN...${NC}"
export ROLE_ARN=$(bash create-iam-role.sh)
echo -e "${CYAN}Role ARN: $ROLE_ARN${NC}"

# Step 4: Create ECR Repository (if it doesn't exist)
echo -e "${YELLOW}📦 Ensuring ECR repository exists...${NC}"
aws ecr describe-repositories --repository-names ${ECR_REPO} --region ${AWS_REGION} --no-cli-pager 2>/dev/null || {
    echo -e "${YELLOW}ECR repository '${ECR_REPO}' does not exist.${NC}"
    echo -e "${CYAN}Do you want to create it? (y/N): ${NC}"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Creating ECR repository: ${ECR_REPO}${NC}"
        aws ecr create-repository --repository-name ${ECR_REPO} --region ${AWS_REGION} --no-cli-pager
    else
        echo -e "${RED}❌ ECR repository creation cancelled. Stopping initialization.${NC}"
        exit 1
    fi
}

# Step 5: Build Docker Image
echo -e "${YELLOW}🐳 Building Docker image...${NC}"

# Use the build-docker.sh script
if ! bash build-docker.sh; then
    echo -e "${RED}❌ Docker build failed. Stopping initialization.${NC}"
    exit 1
fi

# Tag the image for ECR
docker tag my-agent-service ${ACCOUNTID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest

# Step 6: Push to ECR
echo -e "${YELLOW}📤 Pushing to ECR...${NC}"
# Login to ECR first
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ACCOUNTID}.dkr.ecr.${AWS_REGION}.amazonaws.com

docker push ${ACCOUNTID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest

# Step 7: Create Agent Runtime
echo -e "${YELLOW}🆕 Creating new agent runtime...${NC}"

RUNTIME_RESPONSE=$(aws bedrock-agentcore-control create-agent-runtime \
  --agent-runtime-name ${RUNTIME_NAME} \
  --agent-runtime-artifact containerConfiguration={containerUri=${ACCOUNTID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest} \
  --role-arn ${ROLE_ARN} \
  --network-configuration networkMode=PUBLIC \
  --protocol-configuration serverProtocol=HTTP \
  --region ${AWS_REGION} \
  --output json)

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ Error: jq is not installed${NC}"
    echo -e "${YELLOW}Please install jq to parse JSON responses${NC}"
    echo -e "${YELLOW}macOS: brew install jq${NC}"
    echo -e "${YELLOW}Linux: apt-get install jq or yum install jq${NC}"
    echo -e ""
    echo -e "${YELLOW}Full response:${NC}"
    echo "$RUNTIME_RESPONSE"
    exit 1
fi

# Extract runtime ID and ARN from response
RUNTIME_ID=$(echo "$RUNTIME_RESPONSE" | jq -r '.agentRuntimeId // empty')
RUNTIME_ARN=$(echo "$RUNTIME_RESPONSE" | jq -r '.agentRuntimeArn // empty')

# Check if extraction was successful
if [ -z "$RUNTIME_ID" ] || [ -z "$RUNTIME_ARN" ]; then
    echo -e "${RED}❌ Error: Failed to extract runtime ID or ARN from response${NC}"
    echo -e "${YELLOW}Full response:${NC}"
    echo "$RUNTIME_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✅ Initialization complete!${NC}"
echo -e ""
echo -e "${GREEN}🎉 Your agent runtime has been created!${NC}"
echo -e "${CYAN}Runtime ID: ${RUNTIME_ID}${NC}"
echo -e "${CYAN}Runtime ARN: ${RUNTIME_ARN}${NC}"
echo -e ""
echo -e "${YELLOW}⏳ Wait about 1 minute for the runtime to be ready, then test with:${NC}"
echo -e "${CYAN}npm run invoke -- ${RUNTIME_ARN}${NC}"
echo -e ""
echo -e "${YELLOW}📝 To update this runtime in the future:${NC}"
echo -e "${CYAN}npm run update -- ${RUNTIME_ID}${NC}"
echo -e ""
echo -e "${YELLOW}💡 Save your Runtime ID for future updates: ${RUNTIME_ID}${NC}"
