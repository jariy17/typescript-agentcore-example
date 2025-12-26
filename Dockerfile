FROM --platform=linux/arm64 public.ecr.aws/docker/library/node:latest

# Accept build argument for bedrock-agentcore path
ARG BEDROCK_AGENTCORE_PATH=./bedrock-agentcore-sdk-typescript-private

WORKDIR /app

# Copy package files first
COPY package.json package-lock.json* ./

# Copy source code (before linking to avoid conflicts)
COPY src ./src
COPY tsconfig.json ./

# Copy the local bedrock-agentcore package using the build arg
COPY ${BEDROCK_AGENTCORE_PATH} /bedrock-agentcore-package

# Install other dependencies first
RUN npm install

# Link the bedrock-agentcore package globally and then link it to this project
RUN cd /bedrock-agentcore-package && npm install && npm run build && npm link
RUN npm link bedrock-agentcore

# Build TypeScript
RUN npm run build

# Expose port
EXPOSE 8080

# Start the application
CMD ["npm", "start"]