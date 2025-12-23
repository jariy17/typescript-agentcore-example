FROM --platform=linux/arm64 public.ecr.aws/docker/library/node:latest

# Accept build argument for bedrock-agentcore path
ARG BEDROCK_AGENTCORE_PATH=../bedrock-agentcore-sdk-typescript-private

WORKDIR /app

# Copy the local bedrock-agentcore package using the build arg
COPY ${BEDROCK_AGENTCORE_PATH} /bedrock-agentcore-package

# Copy package files
COPY package.json package-lock.json* ./

# Link the bedrock-agentcore package globally and then link it to this project
RUN cd /bedrock-agentcore-package && npm install && npm link
RUN npm link bedrock-agentcore

# Install other dependencies
RUN npm install

# Copy source code
COPY . ./

# Build TypeScript
RUN npm run build

# Expose port
EXPOSE 8080

# Start the application
CMD ["npm", "start"]