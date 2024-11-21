targetScope='subscription'

param locationName string
@allowed([
  'dev'
  'prd'
  'sbx'
  'shd'
  'stg'
  'tst'
  'uat'
])
param environmentName string
param projectName string
param location string
param instance int

resource newResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${projectName}-${environmentName}-${locationName}-${instance}'
  location: location
}

module storageAccount 'storage.bicep' = {
  name: 'storageModule'
  scope: newResourceGroup
  params: {
    storageLocation: location
    storageName: 'st${projectName}${environmentName}${locationName}${instance}'
  }
}

module dataFactory 'data-factory.bicep' = {
  name: 'adf-${projectName}-${environmentName}-${locationName}-${instance}'
  scope: newResourceGroup
  params: {
    location: location
    name: 'adf-${projectName}-${environmentName}-${locationName}-${instance}'
    dfsStorageUrl: storageAccount.outputs.dfsUri
  }
}
