param location string
param name string
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
