// Azure AI Hub Module

@description('Name of the AI Hub')
param name string

@description('Location for the AI Hub')
param location string

@description('Storage Account resource ID')
param storageAccountId string

@description('Key Vault resource ID')
param keyVaultId string

@description('Application Insights resource ID')
param appInsightsId string

@description('Azure OpenAI resource ID')
param openAiId string

@description('Azure OpenAI endpoint')
param openAiEndpoint string

@description('Azure AI Search resource ID')
param searchId string

@description('Azure AI Search endpoint')
param searchEndpoint string

resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: name
  location: location
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: name
    storageAccount: storageAccountId
    keyVault: keyVaultId
    applicationInsights: appInsightsId
    publicNetworkAccess: 'Enabled'
  }
}

// Azure OpenAI Connection
resource openAiConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-04-01' = {
  parent: aiHub
  name: 'aoai-connection'
  properties: {
    category: 'AzureOpenAI'
    target: openAiEndpoint
    authType: 'ApiKey'
    isSharedToAll: true
    credentials: {
      key: listKeys(openAiId, '2023-10-01-preview').key1
    }
    metadata: {
      ApiType: 'Azure'
      ResourceId: openAiId
    }
  }
}

// Azure AI Search Connection
resource searchConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-04-01' = {
  parent: aiHub
  name: 'search-connection'
  properties: {
    category: 'CognitiveSearch'
    target: searchEndpoint
    authType: 'ApiKey'
    isSharedToAll: true
    credentials: {
      key: listAdminKeys(searchId, '2023-11-01').primaryKey
    }
    metadata: {
      ResourceId: searchId
    }
  }
}

output id string = aiHub.id
output name string = aiHub.name
output principalId string = aiHub.identity.principalId
