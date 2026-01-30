// Azure AI Project Module

@description('Name of the AI Project')
param name string

@description('Location for the AI Project')
param location string

@description('AI Hub resource ID')
param aiHubId string

resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: name
  location: location
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: name
    hubResourceId: aiHubId
    publicNetworkAccess: 'Enabled'
  }
}

output id string = aiProject.id
output name string = aiProject.name
output principalId string = aiProject.identity.principalId
