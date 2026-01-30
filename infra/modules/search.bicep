// Azure AI Search Module

@description('Name of the Azure AI Search service')
param name string

@description('Location for the Azure AI Search service')
param location string

@description('SKU for the Azure AI Search service')
@allowed(['free', 'basic', 'standard', 'standard2', 'standard3'])
param sku string = 'basic'

resource searchService 'Microsoft.Search/searchServices@2023-11-01' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    publicNetworkAccess: 'enabled'
    semanticSearch: sku == 'free' ? 'disabled' : 'free'
  }
}

output id string = searchService.id
output name string = searchService.name
output endpoint string = 'https://${searchService.name}.search.windows.net'
