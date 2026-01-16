FROM --platform=linux/arm64 public.ecr.aws/docker/library/node:latest

WORKDIR /app

# Copy package files and the local .tgz dependency
COPY package.json package-lock.json* ./
COPY bedrock-agentcore-0.1.1.tgz ./

# Copy source code
COPY src ./src
COPY tsconfig.json ./

# Install all dependencies (including the .tgz file)
RUN npm install

# Build TypeScript
RUN npm run build

# Expose port
EXPOSE 8080

# Start the application
CMD ["npm", "start"]