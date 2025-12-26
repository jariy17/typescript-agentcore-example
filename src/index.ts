import { z } from 'zod'
import { Agent, AgentStreamEvent, BedrockModel, tool } from '@strands-agents/sdk'
import { BedrockAgentCoreApp } from 'bedrock-agentcore/runtime'

function processEvent(event: AgentStreamEvent): string | undefined {
  // Track agent loop lifecycle
  switch (event.type) {
    case 'beforeInvocationEvent':
      console.log('🔄 Agent loop initialized')
      break
    case 'beforeModelCallEvent':
      console.log('▶️ Agent loop cycle starting')
      break
    case 'afterModelCallEvent':
      console.log(`📬 New message created: ${event.stopData?.message.role}`)
      break
    case 'beforeToolsEvent':
      console.log("About to execute tool!")
      break
    case 'beforeToolsEvent':
      console.log("Finished execute tool!")
      break
    case 'afterInvocationEvent':
      console.log('✅ Agent loop completed')
      break
  }

  // Track tool usage
  if (event.type === 'modelContentBlockStartEvent' && event.start?.type === 'toolUseStart') {
    console.log(`\n🔧 Using tool: ${event.start.name}`)
  }

  // Show text snippets
  if (event.type === 'modelContentBlockDeltaEvent' && event.delta.type === 'textDelta') {
    return event.delta.text
  }
}

const agent = new Agent({
  model: new BedrockModel({
    region: 'us-west-2', // Change to your preferred region
  }),
  tools: [
    tool({
      name: 'calculator',
      description: 'Performs basic arithmetic',
      inputSchema: z.object({
        operation: z.enum(['add', 'subtract', 'multiply', 'divide']),
        a: z.number(),
        b: z.number(),
      }),
      callback: (input) => {
        switch (input.operation) {
          case 'add':
            return input.a + input.b
          case 'subtract':
            return input.a - input.b
          case 'multiply':
            return input.a * input.b
          case 'divide':
            return input.a / input.b
        }
      },
    }),
  ],
})
const app = new BedrockAgentCoreApp({
  config: {
    logging: {
      enabled: true,
      level: 'debug',
    },
  },
  handler: async (request: unknown, context) => {
    console.log('Invocation Session Id:', context.sessionId)
    console.log('Request type:', typeof request)
    console.log('Request:', request)

    const prompt =
      typeof request === 'string' ? request : JSON.stringify(request)
    console.log('Prompt: ', prompt)
    return (async function* () {
      for await (const event of agent.stream(prompt)) {
        const text = processEvent(event)
        if (text) yield text
      }
    })()
  },
  websocketHandler: async (socket, context) => {
    console.log(`WebSocket connected for session: ${context.sessionId}`)

    socket.on('message', async (message: Buffer) => {
      try {
        const prompt = message.toString()
        console.log('Prompt: ', prompt)
        for await (const event of agent.stream(prompt)) {
          if (
            event.type === 'modelContentBlockDeltaEvent' &&
            event.delta?.type === 'textDelta'
          ) {
            socket.send(event.delta.text)
          }
        }
      } catch (error) {
        socket.send(
          JSON.stringify({
            error: error instanceof Error ? error.message : 'Unknown error',
          })
        )
      }
    })

    socket.on('close', () => {
      console.log(`WebSocket closed for session: ${context.sessionId}`)
    })
  },
})

app.run()
