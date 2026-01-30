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
    capacity: 10
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

output id string = openAiAccount.id
output name string = openAiAccount.name
output endpoint string = openAiAccount.properties.endpoint
