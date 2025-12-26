import {
  BedrockAgentCoreClient,
  InvokeAgentRuntimeCommand,
} from '@aws-sdk/client-bedrock-agentcore'

// Get runtime ARN from command line argument
const agentRuntimeArn = process.argv[2]
if (!agentRuntimeArn) {
  console.error('Error: Agent runtime ARN is required')
  console.error('Usage: npm run invoke <agent-runtime-arn>')
  process.exit(1)
}

const input_text = 'Calculate 5 plus 3 using the calculator tool'

const client = new BedrockAgentCoreClient({
  region: 'us-west-2',
})

const input = {
  // Generate unique session ID
  runtimeSessionId:
    'test-session-' +
    Date.now() +
    '-' +
    Math.random().toString(10).substring(7),
  agentRuntimeArn,
  qualifier: 'DEFAULT',
  accept: 'text/event-stream',
  contentType: 'application/json',
  payload: JSON.stringify(input_text),
}

console.log('\x1b[36mSession ID:\x1b[0m', input.runtimeSessionId)
console.log('\x1b[33mInput:\x1b[0m', input_text)

const command = new InvokeAgentRuntimeCommand(input)
const response = await client.send(command)
const textResponse = await response.response?.transformToString()

console.log('\x1b[32mResponse:\x1b[0m', textResponse)
console.log('Full Response:', response)
