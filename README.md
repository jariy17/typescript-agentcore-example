# My Agent Service

A Bedrock Agent Core service built with TypeScript and Express.

## Prerequisites

- Node.js 18+
- npm
- Docker
- AWS CLI configured with appropriate permissions
- The `bedrock-agentcore-0.1.1.tgz` file in the project root directory

## Setup

1. Clone this repository
2. Ensure `bedrock-agentcore-0.1.1.tgz` is in the project root directory
3. Install dependencies:
   ```bash
   npm install
   ```
4. Build the project:
   ```bash
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
# Build and run with Docker
docker build -t my-agent-service .
docker run -p 8080:8080 my-agent-service

# Or use the build script
bash build-docker.sh
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

2. The IAM role will be created automatically by the scripts

### First-Time Setup (Initialize)

To create a new agent runtime for the first time:

```bash
# Initialize with default name "my-agent-service"
npm run initialize

# Or specify a custom name
npm run initialize -- my-custom-name

# Example
npm run initialize -- tjariy_bug_bash
```

The initialization process will:
1. Build TypeScript
2. Create IAM role (if needed)
3. Create ECR repository
4. Build and push Docker image
5. Create a new Bedrock Agent Runtime
6. Display the generated Runtime ID (save this for updates!)

**Important**: Save the Runtime ID from the output - you'll need it for updates.

### Updating an Existing Runtime

To update an existing agent runtime:

```bash
# Update with your runtime ID
npm run update -- <runtime-id>

# Example
npm run update -- tjariy_bug_bash-abc1234567
```

**Runtime ID Format**: `<name>-<10-character-suffix>`
- Example: `my-agent-service-abc1234567`
- Pattern: `[a-zA-Z][a-zA-Z0-9_]{0,99}-[a-zA-Z0-9]{10}`

The update process will:
1. Validate runtime ID format
2. Verify runtime exists
3. Build TypeScript
4. Build and push Docker image
5. Update the Bedrock Agent Runtime

### After Deployment

Wait about 1 minute for the update to complete, then test:
```bash
npm run invoke -- <runtime-arn>
```

The ARN will be displayed at the end of the initialize or update process.

## Available Scripts

- `npm start` - Build and run the service locally
- `npm run dev` - Development mode with TypeScript compilation
- `npm run build` - Compile TypeScript
- `npm run invoke -- <runtime-arn>` - Test the service (local or deployed)
- `npm run initialize [name]` - Create a new agent runtime (first-time setup)
- `npm run update -- <runtime-id>` - Update an existing agent runtime
- `npm run lint` - Run ESLint
- `npm run format` - Format code with Prettier
- `npm run check` - Run lint and format

## Project Structure

```
├── src/
│   ├── index.ts          # Main service entry point
│   └── invoke.ts         # Test invocation script
├── Dockerfile            # Docker configuration
├── initialize.sh         # First-time runtime creation script
├── update.sh            # Runtime update script
├── build-docker.sh      # Docker build script
├── create-iam-role.sh   # IAM role creation script
└── package.json         # Dependencies and scripts
```

## Configuration

The service uses the following configuration:
- **Port**: 8080 (configurable via environment)
- **AWS Region**: us-west-2 (configurable in initialize.sh and update.sh)
- **ECR Repository**: Based on runtime name/ID

## Troubleshooting

### Common Issues

1. **Bedrock package not found**: Ensure `bedrock-agentcore-0.1.1.tgz` is in the project root directory
2. **Docker build fails**: Check that Docker is running and you have sufficient permissions
3. **AWS deployment fails**: Verify AWS CLI configuration and IAM permissions
4. **Service not responding**: Check that port 8080 is available and not blocked by firewall

### Logs

Check Docker logs:
```bash
docker logs <container-id>
```

Check AWS CloudWatch logs for deployed service.
