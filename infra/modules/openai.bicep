// Azure OpenAI Service Module

@description('Name of the Azure OpenAI service')
param name string

@description('Location for the Azure OpenAI service')
param location string

@description('GPT model to deploy')
param gptModelName string

@description('GPT model version')
param gptModelVersion string

@description('Embedding model to deploy')
param embeddingModelName string

@description('Embedding model version')
param embeddingModelVersion string

@description('Principal ID of the user to grant OpenAI access')
param principalId string = ''

// Role definition for Cognitive Services OpenAI User
var cognitiveServicesOpenAIUserRole = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'

resource openAiAccount 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: name
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
  }
}

// GPT Model Deployment
resource gptDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = {
  parent: openAiAccount
  name: gptModelName
  sku: {
    name: 'Standard'
    capacity: 30
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: gptModelName
      version: gptModelVersion
    }
  }
}

// Embedding Model Deployment
resource embeddingDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = {
  parent: openAiAccount
  name: embeddingModelName
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: embeddingModelName
      version: embeddingModelVersion
    }
  }
  dependsOn: [
    gptDeployment // Sequential deployment to avoid conflicts
  ]
}

// Assign Cognitive Services OpenAI User role to the principal
resource openAiRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  name: guid(openAiAccount.id, principalId, cognitiveServicesOpenAIUserRole)
  scope: openAiAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesOpenAIUserRole)
    principalId: principalId
    principalType: 'User'
  }
}

output id string = openAiAccount.id
output name string = openAiAccount.name
output endpoint string = openAiAccount.properties.endpoint
