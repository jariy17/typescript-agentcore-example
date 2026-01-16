import { BedrockAgentCoreApp } from 'bedrock-agentcore/runtime'
import { z } from 'zod'

const app = new BedrockAgentCoreApp({
  invocationHandler: {
    process: async (request, context) => {
      const response = {
        message: 'Hello from AgentCore!',
        sessionId: context.sessionId,
        requestId: context.requestId,
        received: request,
      }

      // Return as JSON string
      return JSON.stringify(response)
    },
  },
})

app.run()
