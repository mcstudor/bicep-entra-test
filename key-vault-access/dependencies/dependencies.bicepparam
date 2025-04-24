using 'dependencies.bicep'

param entraGroupName = {
  uniqueName: 'TestKVAccessGroup'
  displayName: 'test-kv-access-group'
}

param keyVaultSecrets = [
  {
    key: 'test-key-value-01'
    secret: 'test-secret-value-01'
  }
  {
    key: 'test-key-value-02'
    secret: 'test-secret-value-02'
  }
  {
    key: 'test-key-value-03'
    secret: 'test-secret-value-03'
  }
]

param adminPrincipalId = readEnvironmentVariable('adminPrincipalId', '') 

param resourceGroupName = readEnvironmentVariable('entraResourceGroup', 'EntraTestRG')
