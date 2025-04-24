extension microsoftGraphV1
targetScope = 'subscription'

metadata name = 'Required resources'
metadata description = 'Set up required resources for web applications.'

param resourceGroupName string

param adminPrincipalId string?

var kvAdminRoleAssignment = !empty(adminPrincipalId) ? [
  {
    principalId: adminPrincipalId
    roleDefinitionIdOrName: 'Key Vault Administrator'
  }
] : []

param entraGroupName {
  displayName: string
  uniqueName: string
}

import { keyVaultSecretType } from 'kv-secret.bicep'
param keyVaultSecrets keyVaultSecretType[]

param location string = deployment().location

resource group 'Microsoft.Graph/groups@v1.0' = {
  displayName: entraGroupName.displayName
  mailEnabled: false
  mailNickname: entraGroupName.displayName
  securityEnabled: true
  uniqueName: entraGroupName.uniqueName
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module kv 'br/public:avm/res/key-vault/vault:0.12.1' = {
  name: 'test-kv-deploy'
  scope: resourceGroup
  params: {
    name: 'test-kv-01-${take(uniqueString(resourceGroup.name), 5)}'
    location: location
    enableSoftDelete: false
    roleAssignments: union(
      [
        {
          principalId: group.id
          roleDefinitionIdOrName: 'Key Vault Secrets User'
        }
      ],
      kvAdminRoleAssignment
    )
  }
}

module kvSecret 'kv-secret.bicep' = {
  name: 'test-kv-secret'
  scope: resourceGroup
  params: {
    keyVaultName: kv.outputs.name
    keyVaultSecrets: keyVaultSecrets
  }
}

module appServicePlan 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: 'test-app-service-plan-deploy'
  scope: resourceGroup
  params: {
    name: 'test-app-service-plan-${take(uniqueString(resourceGroup.name), 5)}'
    location: location
    skuCapacity: 1
    zoneRedundant: false
    skuName: 'F1'
    kind: 'windows'
  }
}

output resourceGroupName string = resourceGroup.name
output appServicePlanResourceId string = appServicePlan.outputs.resourceId
output keyVaultAccessGroupUniqueName string = group.uniqueName
output keyVaultName string = kv.name
import { keyVaultSecretUriType } from 'kv-secret.bicep'
output keyVaultSecretUri keyVaultSecretUriType[] = kvSecret.outputs.keyVaultSecretUris
