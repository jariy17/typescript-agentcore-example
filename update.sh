#!/bin/bash

# Update script for my-agent-service
# Usage: ./update.sh <runtime-id>
#
# Arguments:
#   runtime-id - Required: The full agent runtime ID (format: <name>-<10-char-suffix>)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting update process...${NC}"

# Check if runtime ID is provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Runtime ID required${NC}"
    echo -e "${RED}Usage: ./update.sh <runtime-id>${NC}"
    echo -e "${RED}Example: ./update.sh my-agent-service-abc1234567${NC}"
    exit 1
fi

RUNTIME_ID="$1"

# Validate runtime ID format: [a-zA-Z][a-zA-Z0-9_]{0,99}-[a-zA-Z0-9]{10}
# Must be: <name>-<exactly-10-alphanumeric-chars>
if ! [[ "$RUNTIME_ID" =~ ^[a-zA-Z][a-zA-Z0-9_]{0,99}-[a-zA-Z0-9]{10}$ ]]; then
    echo -e "${RED}❌ Error: Invalid runtime ID format${NC}"
    echo -e "${RED}Runtime ID must match: <name>-<10-characters>${NC}"
    echo -e "${RED}Pattern: [a-zA-Z][a-zA-Z0-9_]{0,99}-[a-zA-Z0-9]{10}${NC}"
    echo -e ""
    echo -e "${YELLOW}Valid examples:${NC}"
    echo -e "  - my_agent_service-abc1234567"
    echo -e "  - tjariy_bug_bash-0123456789"
    echo -e ""
    echo -e "${YELLOW}Your ID: ${RUNTIME_ID}${NC}"
    exit 1
fi

# Step 1: Build TypeScript
echo -e "${YELLOW}📦 Building TypeScript...${NC}"
npm run build

# Step 2: Set Environment Variables
echo -e "${YELLOW}🔧 Setting up environment variables...${NC}"
export ACCOUNTID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-west-2

echo -e "${CYAN}Account ID: $ACCOUNTID${NC}"
echo -e "${CYAN}Region: $AWS_REGION${NC}"
echo -e "${CYAN}Runtime ID: $RUNTIME_ID${NC}"

# Step 3: Get runtime configuration and extract ECR repo
echo -e "${YELLOW}🔍 Getting runtime configuration...${NC}"
RUNTIME_CONFIG=$(aws bedrock-agentcore-control get-agent-runtime --agent-runtime-id "${RUNTIME_ID}" --region ${AWS_REGION} --output json)

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error: Runtime '${RUNTIME_ID}' does not exist${NC}"
    echo -e "${YELLOW}To create a new runtime, use: ./initialize.sh [runtime-name]${NC}"
    exit 1
fi

# Extract the runtime ARN and current container URI
RUNTIME_ARN=$(echo "$RUNTIME_CONFIG" | jq -r '.agentRuntimeArn // empty')
CURRENT_IMAGE_URI=$(echo "$RUNTIME_CONFIG" | jq -r '.agentRuntimeArtifact.containerConfiguration.containerUri // empty')

if [ -z "$RUNTIME_ARN" ]; then
    echo -e "${RED}❌ Error: Could not extract runtime ARN${NC}"
    exit 1
fi

if [ -z "$CURRENT_IMAGE_URI" ]; then
    echo -e "${RED}❌ Error: Could not extract container URI from runtime${NC}"
    exit 1
fi

# Extract ECR repo name from URI format: <account>.dkr.ecr.<region>.amazonaws.com/<repo-name>:tag
export ECR_REPO=$(echo "$CURRENT_IMAGE_URI" | sed -n 's|.*amazonaws\.com/\([^:]*\):.*|\1|p')

if [ -z "$ECR_REPO" ]; then
    echo -e "${RED}❌ Error: Could not parse ECR repository name from URI${NC}"
    echo -e "${YELLOW}Container URI: ${CURRENT_IMAGE_URI}${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Runtime exists${NC}"
echo -e "${CYAN}ECR Repo: $ECR_REPO${NC}"

# Step 4: Get IAM Role ARN
echo -e "${YELLOW}🔑 Getting IAM Role ARN...${NC}"
export ROLE_ARN=$(bash create-iam-role.sh)
echo -e "${CYAN}Role ARN: $ROLE_ARN${NC}"

# Step 5: Build Docker Image
echo -e "${YELLOW}🐳 Building Docker image...${NC}"

# Use the build-docker.sh script
if ! bash build-docker.sh; then
    echo -e "${RED}❌ Docker build failed. Stopping update.${NC}"
    exit 1
fi

# Tag the image for ECR
docker tag my-agent-service ${ACCOUNTID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest

# Step 6: Push to ECR
echo -e "${YELLOW}📤 Pushing to ECR...${NC}"
# Login to ECR first
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ACCOUNTID}.dkr.ecr.${AWS_REGION}.amazonaws.com

docker push ${ACCOUNTID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest

# Step 7: Update Runtime
echo -e "${YELLOW}🔄 Updating agent runtime...${NC}"
aws bedrock-agentcore-control update-agent-runtime \
  --agent-runtime-id "${RUNTIME_ID}" \
  --agent-runtime-artifact "{\"containerConfiguration\": {\"containerUri\": \"${ACCOUNTID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:latest\"}}" \
  --role-arn "${ROLE_ARN}" \
  --network-configuration "{\"networkMode\": \"PUBLIC\"}" \
  --protocol-configuration serverProtocol=HTTP \
  --region ${AWS_REGION} \
  --no-cli-pager

echo -e "${GREEN}✅ Update complete!${NC}"
echo -e ""
echo -e "${YELLOW}⏳ Wait about 1 minute for the update to complete, then test with:${NC}"
echo -e "${CYAN}npm run invoke -- ${RUNTIME_ARN}${NC}"
echo -e ""
echo -e "${YELLOW}📝 To update this runtime again:${NC}"
echo -e "${CYAN}npm run update -- ${RUNTIME_ID}${NC}"
