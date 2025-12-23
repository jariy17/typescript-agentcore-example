import {
  BedrockAgentCoreClient,
  InvokeAgentRuntimeCommand,
} from '@aws-sdk/client-bedrock-agentcore'

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
  // Replace with your actual runtime ARN
  agentRuntimeArn:
    'arn:aws:bedrock-agentcore:us-west-2:725476964917:runtime/my_agent_service-mK9sv7H15K',
  qualifier: 'DEFAULT',
  payload: new TextEncoder().encode(input_text),
}

const command = new InvokeAgentRuntimeCommand(input)
const response = await client.send(command)
const textResponse = await response.response?.transformToString()

console.log('Response:', textResponse)
