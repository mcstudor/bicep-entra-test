metadata name = 'Web App deployment'
metadata description = 'Empty application with App Settings and a System Managed Identity.'

param appName string
param serverFarmId string
param appSettingKeyVaultPairs object
param userAssignedResourceId string
param location string = resourceGroup().location
var uniqueAppName = '${appName}-${take(uniqueString(resourceGroup().id), 6)}'

module webApp 'br/public:avm/res/web/site:0.15.1' = {
  name: '${uniqueAppName}-deploy'
  params: {
    kind: 'app'
    name: uniqueAppName
    serverFarmResourceId: serverFarmId
    location: location
    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds: [
        userAssignedResourceId
      ]
    }
    keyVaultAccessIdentityResourceId: userAssignedResourceId
    appSettingsKeyValuePairs: appSettingKeyVaultPairs
    siteConfig: {
      alwaysOn: false
    }
  }
}

output webAppName string = webApp.outputs.name
