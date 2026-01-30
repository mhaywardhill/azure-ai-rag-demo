// Log Analytics Workspace Module

@description('Name of the Log Analytics workspace')
param name string

@description('Location for the Log Analytics workspace')
param location string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

output id string = logAnalyticsWorkspace.id
output name string = logAnalyticsWorkspace.name
