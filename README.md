# My Agent Service

A Bedrock Agent Core service built with TypeScript and Express.

## Prerequisites

- Node.js 18+ 
- npm
- Docker
- AWS CLI configured with appropriate permissions
- The bedrock-agentcore TypeScript SDK must be in the same directory as the Dockerfile

## Setup

1. Clone this repository
2. **Required**: Copy the bedrock-agentcore TypeScript SDK into this directory
3. Install dependencies for this respository:
   ```bash
   npm install
   ```
4. Go into bedrock-agentcore directory and build and link the repository
   ```bash
   npm install
   npm run build
   npm link
   ```
5. Go back to this repository and to link local bedrock-agentore 
  ```bash
   npm link bedrock-agentcore
   npm run build 
   ```

## Running Locally

### Option 1: Direct Node.js (Recommended for development)
```bash
# Build and run the service
npm start

# Or for development with auto-rebuild
npm run dev
```

The service will be available at `http://localhost:8080`

### Option 2: Docker
```bash
# Build and run with Docker using default bedrock-agentcore path
docker build --build-arg BEDROCK_AGENTCORE_PATH=../bedrock-agentcore-sdk-typescript-private -t my-agent-service .
docker run -p 8080:8080 my-agent-service

# Or use the build script
bash build-docker.sh ../bedrock-agentcore-sdk-typescript-private
docker run -p 8080:8080 my-agent-service
```

## Testing

Test your local service:
```bash
npm run invoke
```

## Deployment

### Prerequisites for Deployment

1. AWS CLI configured with permissions for:
   - ECR (Elastic Container Registry)
   - Bedrock Agent Core
   - IAM (to get role ARN)
   - STS (to get account ID)

2. Create the required IAM role:
   ```bash
   bash create-iam-role.sh
   ```

### Deploy to AWS

```bash
# Deploy with runtime ID (required) and TypeScript SDK path
npm run deploy -- your-runtime-id-here ./path-to-typescript-sdk

# Example
npm run deploy -- my-agent-service-abc123def456 ./bedrock-agentcore-sdk-typescript-private
```

The deployment process will:
1. Lint and format your code
2. Build TypeScript
3. Create/verify ECR repository
4. Build and push Docker image
5. Update the Bedrock Agent Runtime

### After Deployment

Wait about 1 minute for the update to complete, then test:
```bash
npm run invoke
```

## Available Scripts

- `npm start` - Build and run the service locally
- `npm run dev` - Development mode with TypeScript compilation
- `npm run build` - Compile TypeScript
- `npm run invoke` - Test the service (local or deployed)
- `npm run deploy -- <runtime-id> [bedrock-path]` - Deploy to AWS
- `npm run lint` - Run ESLint
- `npm run format` - Format code with Prettier
- `npm run check` - Run lint and format

## Project Structure

```
├── src/
│   ├── index.ts          # Main service entry point
│   └── invoke.ts         # Test invocation script
├── Dockerfile            # Docker configuration
├── deploy.sh            # AWS deployment script
├── build-docker.sh      # Docker build script
├── create-iam-role.sh   # IAM role creation script
└── package.json         # Dependencies and scripts
```

## Configuration

The service uses the following configuration:
- **Port**: 8080 (configurable via environment)
- **AWS Region**: us-west-2 (configurable in deploy.sh)
- **ECR Repository**: my-agent-service

## Troubleshooting

### Common Issues

1. **Bedrock package not found**: Ensure the bedrock-agentcore package path is correct
2. **Docker build fails**: Check that Docker is running and you have sufficient permissions
3. **AWS deployment fails**: Verify AWS CLI configuration and IAM permissions
4. **Service not responding**: Check that port 8080 is available and not blocked by firewall

### Logs

Check Docker logs:
```bash
docker logs <container-id>
```

Check AWS CloudWatch logs for deployed service.
