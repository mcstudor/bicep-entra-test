param keyVaultSecrets keyVaultSecretType[]
param keyVaultName string
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}
resource secrets 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = [
  for secret in keyVaultSecrets: {
    parent: kv
    name: secret.key
    properties: {
      value: secret.secret
    }
  }
]

var kvSecretsLength = length(keyVaultSecrets)
output keyVaultSecretUris keyVaultSecretUriType[] = [
  for i in range(0, kvSecretsLength): {
    SecretUri: secrets[i].properties.secretUri
    SecretUriWithVersion: secrets[i].properties.secretUriWithVersion
  }
]

@export()
type keyVaultSecretUriType = {
  SecretUri: string
  SecretUriWithVersion: string
}

@export()
type keyVaultSecretType = {
  key: string
  @secure()
  secret: string
}
