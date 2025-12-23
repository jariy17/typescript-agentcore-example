import WebSocket from 'ws'

/**
 * Simple WebSocket client to test the agent's WebSocket endpoint
 */
export async function invokeWebSocketAgent(message: string, url = 'ws://localhost:8080/ws'): Promise<void> {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(url, {
      headers: {
        'x-amzn-bedrock-agentcore-runtime-session-id': 'test-session-' + Date.now()
      }
    })

    ws.on('open', () => {
      console.log('WebSocket connected')
      ws.send(message)
    })

    ws.on('message', (data: Buffer) => {
      console.log('Response:', data.toString())
      ws.close()
      resolve()
    })

    ws.on('error', (error: Error) => {
      console.error('WebSocket error:', error)
      reject(error)
    })

    ws.on('close', () => {
      console.log('WebSocket connection closed')
    })
  })
}

// Example usage
if (import.meta.url === `file://${process.argv[1]}`) {
  invokeWebSocketAgent('Calculate 5 + 3')
    .catch(console.error)
}
