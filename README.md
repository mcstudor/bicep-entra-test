# Bicep Entra Test

Test deployments using the Bicep Entra extension.


## Key Vault Access test

This test represents a template applied to many Web Apps sharing a single Key Vault and App Service Plan. 

### Setup

- Setup an Azure subscription.
- Install [Azure Powershell module](https://learn.microsoft.com/en-us/powershell/azure/get-started-azureps?view=azps-13.3.0).
- Run `Connect-AzAccount` and select the target subscription

### Apply permissions to system-assigned identity

#### Procedure

Running the deployment script, [New-KvAccessDeployment.ps1](./key-vault-access/New-KvAccessDeployment.ps1), performs all step described below. The dependencies deployment simulates existing resources that service many Web Apps. Due to current limitations, `Microsoft.Graph` resources cannot be deployed using Deployment Stacks and are in a separate Bicep template.

1. Deploy dependencies. Resource Group, App Service Plan, Key Vault, Key Vault Secrets, and a Entra security Group. This Group has `Key Vault Secrets User` permissions to the created Key Vault. 
2. Deploy Web Apps with Deployment Stack. These apps have App Settings with references to the Key Vault Secrets. They are all using System Managed Identities. 
3. Redeploy Entra Group. The existing group is modified by appending the Web App PrincipalIds as a member. 


#### Results

When Web Apps are deployed when it does not have permissions to access the Key Vault, it fails to resolve Key Vault references. Viewing permissions for app in the portal indicates proper permissions set by Group access. Attempts to mitigate the issue with no success:

- Deploying with Key Vault references in environment variables
- Deploying without references, then adding references after 
- Refreshing environment variables
- Restarting the application
- Stopping/Starting the application
- Adding new Key Vault references
- Removing all references and applying new references
- Redeploying the template
- Creating an RBAC enabled Entra Group
- Applying a `keyVaultReferenceIdentity` value for the application
- Removing and adding the system-assigned identity to the Group
- Removing Key Vault RBAC permissions from the Group and adding them again
- Granting elevated rights (Owner) to the Group

Once deployed this way, the only mitigation found was to add Key Vault RBAC permissions for the system-assigned identity directly. Removing these permissions also did not resolve the issue. 


### Apply permissions to user-assigned identity

#### Procedure

Running the deployment script, [New-KvAccessDeployment.ps1](./key-vault-access-umi/New-KvAccessDeployment.ps1), performs all step described below. The dependencies deployment simulates existing resources that service many Web Apps. Due to current limitations, `Microsoft.Graph` resources cannot be deployed using Deployment Stacks and are in a separate Bicep template, including user-managed identity.

1. Deploy dependencies. Resource Group, App Service Plan, Key Vault, Key Vault Secrets, and a Entra security Group. This Group has `Key Vault Secrets User` permissions to the created Key Vault. 
2. Deploy a user-managed identity. This identity is added to the Entra group. 
3. Deploy Web Apps with Deployment Stack. These apps have App Settings with references to the Key Vault Secrets. The application is configured to use user-managed identity.

#### Results

Web Apps deployed this way successfully reference Key Vault in environment variables. The Identity is not associated to the Web App's Deployment Stack, but this limitation will be addressed in future Bicep extension development. User-managed identities add a small amount of overhead to managed. No other limitations were noted.


