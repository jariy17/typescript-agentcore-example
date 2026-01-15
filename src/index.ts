import { BedrockAgentCoreApp } from 'bedrock-agentcore/runtime'
import { z } from 'zod'

const app = new BedrockAgentCoreApp({
  invocationHandler: {
    process: async (request, context) => {
      return {
        message: 'Hello from AgentCore!',
        sessionId: context.sessionId,
        requestId: context.requestId,
        received: request
      }
    }
  }
})

app.run()