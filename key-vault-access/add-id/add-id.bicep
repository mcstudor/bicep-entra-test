targetScope = 'subscription'
metadata name = 'Add Principal IDs to Group'
metadata description = 'Appends principal IDs to an existing Entra Group.'

extension microsoftGraphV1

param groupName string
param webAppPrincipalIds string[]

resource group 'Microsoft.Graph/groups@v1.0' existing = {
  uniqueName: groupName
}

resource groupMember 'Microsoft.Graph/groups@v1.0' = {
  displayName: group.displayName
  mailEnabled: group.mailEnabled
  mailNickname: group.mailNickname
  securityEnabled: group.securityEnabled
  uniqueName: group.uniqueName
  members: {
    relationships: webAppPrincipalIds
    relationshipSemantics: 'append'
  }
  
}
