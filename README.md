# Bicep Role Assignment

There are numerous references for how to assign roles in Bicep. 

1. The standard docs https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/scenarios-rbac
2. A blog post which makes the role definition id less janky https://www.jvandertil.nl/posts/2022-06-22_easyazurerbacwithbicep/
3. Another blog post building on that last one https://yourazurecoach.com/2023/02/02/my-developer-friendly-bicep-module-for-role-assignments/

But none of those quite met my needs. 

I to create a Storage Account and an Azure Data Factory with a Linked Service in the ADF that used Managed Identity to access the storage. And I wanted a re-usable module for hiding the ugly details of role assignment.

I didn't want to hard-code references to the standard roles, so 2 and 3 above seemed appealing. But they had a problem: to be able to scope the role assignment to just the storage account (not the subscription or resource group), you need a reference to that storage resource. If you do that inside the role assignment module, then you have to specify the resource type as a hard-coded string (that's what 2, above did). 

Number 2 does it like this:

```bicep
param storageAccountName string
param principalId string

@allowed[
    'Device'
    'ForeignGroup'
    'Group'
    'ServicePrincipal'
    'User'
    ''
]
param principalType string = ''

@allowed([
    'Storage Blob Data Contributor'
    'Storage Blob Data Reader'
])
param roleDefinition string

var roles = {
    // See https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles for these mappings and more.
    'Storage Blob Data Contributor': '/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    'Storage Blob Data Reader': '/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
}

var roleDefinitionId = roles[roleDefinition]

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
    name: storageAccountName
}

resource roleAuthorization 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
    // Generate a unique but deterministic resource name
    name: guid('storage-rbac', storageAccount.id, resourceGroup().id, principalId, roleDefinitionId)
    scope: storageAccount
    properties: {
        principalId: principalId
        roleDefinitionId: roleDefinitionId
        principalType: empty(principalType) ? null : principalType
    }
}
```

Which is great, but stops the module from being re-usable for other target objects. 

What I eventually realised is that you can separate the part where we get the standard role id from the part where we assign the role. Then, the re-usable bit doesn't have to be tied to any particular type of resource. That is where [standard-role.bicep](standard-role.bicep) comes in. It's able to suggest standard role names and hide them away, but it doesn't try to assign the role. So you don't have to worry about passing around a resource in Bicep. 

Using this module, our role assignment is simple (from [data-factory.bicep](data-factory.bicep))

```bicep
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
```

I still had to specify that the target was a storage account, but **it didn't have to be in the reusable bit!**