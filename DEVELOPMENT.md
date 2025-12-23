# Development Guide

## Docker-Based Development Workflow

This project uses Docker for both local development and deployment to ensure consistency across environments.

## Quick Start

### Local Development with Docker
```bash
# Build and run locally with Docker
npm start

# This will:
# 1. Build the Docker image with your local bedrock-agentcore package
# 2. Run the container on port 8080
```

### Local Development without Docker
```bash
# Run directly with Node.js (for faster iteration)
npm run dev

# Test the agent
npm run invoke
```

### Deploy to AWS
```bash
# Deploy with your runtime ID
./deploy.sh my-agent-service-XXXXXXXXXX

# Or with custom bedrock-agentcore path
./deploy.sh my-agent-service-XXXXXXXXXX /path/to/bedrock-agentcore

# Or use npm script (will prompt for runtime ID)
npm run deploy
```

## Project Structure

```
├── src/
│   ├── index.ts          # Main agent handler
│   └── invoke.ts         # Test script for deployed agent
├── Dockerfile            # Docker configuration
├── build-docker.sh       # Docker build script
├── deploy.sh            # AWS deployment script
└── package.json         # Dependencies and scripts
```

## Available Scripts

- `npm start` - Build Docker image and run locally
- `npm run dev` - Run locally without Docker (faster for development)
- `npm run build` - Compile TypeScript
- `npm run invoke` - Test the deployed agent
- `npm run deploy` - Deploy to AWS (interactive)
- `npm run lint` - Check code style
- `npm run format` - Format code

## Docker Configuration

The project uses a local `bedrock-agentcore` package via npm link. The Docker setup handles this by:

1. **package.json**: Uses `file:../bedrock-agentcore-sdk-typescript-private` dependency
2. **Dockerfile**: Copies the local package during build
3. **build-docker.sh**: Handles path configuration via environment variables

### Custom bedrock-agentcore Path

Set the path via environment variable:
```bash
BEDROCK_AGENTCORE_PATH=/custom/path npm start
```

Or pass it to deploy script:
```bash
./deploy.sh my-runtime-id /custom/path
```

## Testing

### Local Testing
```bash
# Start the service
npm start

# In another terminal, test with curl
curl -X POST http://localhost:8080/invocations \
  -H "Content-Type: application/json" \
  -H "x-amzn-bedrock-agentcore-runtime-session-id: test-123" \
  -d '"What is 5 plus 3?"'
```

### AWS Testing
```bash
# Test deployed agent
npm run invoke
```

## Prerequisites

- **Docker Desktop** - For containerized development
- **AWS CLI** - Configured with appropriate permissions
- **Node.js 20+** - For local development
- **bedrock-agentcore package** - Linked locally or at specified path

### Required AWS Resources
- ECR repository (created automatically by deploy script)
- IAM role `BedrockAgentCoreRuntimeRole`
- Agent runtime deployed with known runtime ID

## Troubleshooting

### Docker Build Issues
- Ensure bedrock-agentcore path exists
- Check Docker Desktop is running
- Verify npm link is working locally

### Deployment Issues
- Verify AWS CLI credentials
- Check IAM role exists
- Ensure runtime ID is correct

### Local Development Issues
- Run `npm install` to ensure dependencies
- Check TypeScript compilation with `npm run build`
- Verify bedrock-agentcore package is properly linked