param location string
param name string
param storageName string
param dfsStorageUrl string

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

resource storageService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  name: 'storageService'
  parent: dataFactory
  properties: {
    type:'AzureBlobFS'
    typeProperties: {
      url: dfsStorageUrl
    }
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-04-01' existing = {
  name: storageName
}

module storageAccountContributorRole 'standard-role.bicep' = {
  name: 'storageAccountContributorRole'
  params: {standardRoleName:'Storage Account Contributor'}
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(storageName, 'Storage Account Contributor', dataFactory.id)
  scope: storageAccount
  properties: {
    roleDefinitionId: storageAccountContributorRole.outputs.standardRoleId
    principalId: dataFactory.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
