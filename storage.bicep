param storageLocation string
param storageName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: storageName
  location: storageLocation
  sku: {
    name: 'Standard_RAGRS'
  }
  kind: 'StorageV2'
  properties: { 
    minimumTlsVersion: 'TLS1_2'
    encryption: {
      requireInfrastructureEncryption:true
    }
  }
}

output dfsUri string = storageAccount.properties.primaryEndpoints.dfs
