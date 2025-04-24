#Requires -Modules Az.Resources
param (
    [Parameter(Mandatory = $true)][string]$ResourceGroupName,
    [Parameter(Mandatory = $true)][string]$Location,
    [string]$AdminPrincipalId,
    [int]$DeploymentNameSuffix=1,
    [int][ValidateScript({ $_ -gt 0 })]$WebAppCount = 1,
    [string][ValidateScript({ Test-Path $_ })]$DependenciesParamFile = "$PSScriptRoot/dependencies/dependencies.bicepparam",
    [string][ValidateScript({ Test-Path $_ })]$WebAppTemplateFile = "$PSScriptRoot/web-apps/webapp.bicep",
    [string][ValidateScript({ Test-Path $_ })]$AddIdTemplateFile = "$PSScriptRoot/add-id/add-id.bicep"
)
$ErrorActionPreference = "Stop"
# Establish environment variables for .bicepparms
$env:entraResourceGroup = $ResourceGroupName
$env:adminPrincipalId = $AdminPrincipalId
# Get Bicep file locations
$dFile = Get-Item $DependenciesParamFile
$wFile = Get-Item $WebAppTemplateFile
$aFile = Get-Item $AddIdTemplateFile

# Deploy dependencies
$deployParams = @{
    Name = "entra-id-test-dependencies-$DeploymentNameSuffix"
    TemplateParameterFile = $dFile.FullName
    Location = $Location
    Verbose = $Verbose
}
$dependencies = New-AzDeployment @deployParams

# Deploy apps
$webApps = 1 .. $WebAppCount | ForEach-Object {
    $appSettings = @{}
    $dependencies.Outputs.keyVaultSecretUri.Value | ForEach-Object -Begin { $i = 1 } {
        $appSettings.Add("TestKey$i", "@Microsoft.KeyVault(SecretUri=$($_['SecretUri'].Value))")
        $i++
    }
    $templateParams = [hashtable]@{
        appName                 = "test-web-app-$_"
        serverFarmId            = $dependencies.outputs.appServicePlanResourceId.value
        appSettingKeyVaultPairs = $appSettings
        location                = $Location
    }
    $deployParams = @{
        Name                    = "$($templateParams.appName)-stack"
        ResourceGroupName       = $dependencies.Outputs.resourceGroupName.value
        ActionOnUnmanage        = 'deleteAll'
        DenySettingsMode        = 'None'
        TemplateFile            = $wFile.FullName
        TemplateParameterObject = $templateParams
        Force                   = $true
    }
    Set-AzResourceGroupDeploymentStack @deployParams
}

# Redeploy Entra Group with new Principal IDs
$deployParams = @{
    Name                    = 'add-webapp-ids'
    TemplateFile            = $aFile.FullName
    Location                = $Location
    TemplateParameterObject = [hashtable]@{
        groupName          = $dependencies.Outputs.keyVaultAccessGroupUniqueName.value
        webAppPrincipalIds = [array]$webApps.outputs.webAppPrincipalId.value
    }
}
$addId = New-AzDeployment @deployParams


@{
    dependencies = $dependencies
    webApps      = $webApps
    entraAddIds  = $addId
}