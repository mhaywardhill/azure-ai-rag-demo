// Azure AI RAG Demo - Main Bicep Template
// Based on: https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/04-Use-own-data.html

targetScope = 'resourceGroup'

@description('Location for all resources')
param location string = 'swedencentral'

@description('Unique suffix for resource names')
param uniqueSuffix string = substring(uniqueString(resourceGroup().id), 0, 6)

@description('Name of the AI Hub')
param aiHubName string = 'ai-hub-${uniqueSuffix}'

@description('Name of the AI Project')
param aiProjectName string = 'ai-project-rag-demo'

@description('Name of the Azure OpenAI service')
param openAiName string = 'openai-${uniqueSuffix}'

@description('Name of the Azure AI Search service')
param searchName string = 'search-${uniqueSuffix}'

@description('Name of the Storage Account')
param storageName string = 'storage${uniqueSuffix}'

@description('Name of the Key Vault')
param keyVaultName string = 'kv-${uniqueSuffix}'

@description('Name of the Application Insights')
param appInsightsName string = 'appi-${uniqueSuffix}'

@description('Name of the Log Analytics Workspace')
param logAnalyticsName string = 'log-${uniqueSuffix}'

@description('SKU for Azure AI Search')
@allowed(['free', 'basic', 'standard'])
param searchSku string = 'basic'

@description('GPT model to deploy')
param gptModelName string = 'gpt-4o'

@description('GPT model version')
param gptModelVersion string = '2024-05-13'

@description('Embedding model to deploy')
param embeddingModelName string = 'text-embedding-ada-002'

@description('Embedding model version')
param embeddingModelVersion string = '2'

@description('Principal ID of the user to grant OpenAI access (leave empty to skip role assignment)')
param principalId string = ''

// Storage Account
module storage 'modules/storage.bicep' = {
  name: 'storage-deployment'
  params: {
    name: storageName
    location: location
  }
}

// Key Vault
module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault-deployment'
  params: {
    name: keyVaultName
    location: location
  }
}

// Log Analytics Workspace
module logAnalytics 'modules/loganalytics.bicep' = {
  name: 'loganalytics-deployment'
  params: {
    name: logAnalyticsName
    location: location
  }
}

// Application Insights
module appInsights 'modules/appinsights.bicep' = {
  name: 'appinsights-deployment'
  params: {
    name: appInsightsName
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
  }
}

// Azure AI Search
module search 'modules/search.bicep' = {
  name: 'search-deployment'
  params: {
    name: searchName
    location: location
    sku: searchSku
  }
}

// Azure OpenAI Service
module openAi 'modules/openai.bicep' = {
  name: 'openai-deployment'
  params: {
    name: openAiName
    location: location
    gptModelName: gptModelName
    gptModelVersion: gptModelVersion
    embeddingModelName: embeddingModelName
    embeddingModelVersion: embeddingModelVersion
    principalId: principalId
  }
}

// Azure AI Hub
module aiHub 'modules/aihub.bicep' = {
  name: 'aihub-deployment'
  params: {
    name: aiHubName
    location: location
    storageAccountId: storage.outputs.id
    keyVaultId: keyVault.outputs.id
    appInsightsId: appInsights.outputs.id
    openAiId: openAi.outputs.id
    openAiEndpoint: openAi.outputs.endpoint
    searchId: search.outputs.id
    searchEndpoint: search.outputs.endpoint
  }
}

// Azure AI Project
module aiProject 'modules/aiproject.bicep' = {
  name: 'aiproject-deployment'
  params: {
    name: aiProjectName
    location: location
    aiHubId: aiHub.outputs.id
  }
}

// Outputs
output resourceGroupName string = resourceGroup().name
output aiHubName string = aiHub.outputs.name
output aiProjectName string = aiProject.outputs.name
output openAiName string = openAi.outputs.name
output openAiEndpoint string = openAi.outputs.endpoint
output searchName string = search.outputs.name
output searchEndpoint string = search.outputs.endpoint
output storageName string = storage.outputs.name
output keyVaultName string = keyVault.outputs.name
output appInsightsName string = appInsights.outputs.name
