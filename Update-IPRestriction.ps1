<#
.SYNOPSIS

This script checks if Application Gateway's public IP is the same as IP Restriction on App services and updates it if not.
The old IP Restriction will be overwritten with current Public IP of selected Application Gateway. This has to be correlated
with DNS update if only traffic via Appclication Gateway is supposed to be allowed. No defaults for parameters are provided.
.PARAMETER AzureClientId

Azure Service Principal username.
.PARAMETER AzureClientSecret

Azure Service Principal key.
.PARAMETER AzureTenantId

Azure Tenant.
.PARAMETER AzureSubcriptionId

Azure subscription the script runs against.
.PARAMETER ResourceGroupName

Resource Group of App Service to be updated.
.PARAMETER WebAppName

Name of App Service to be updated.
.PARAMETER AppGwName

Name of Application Gateway to be queried.
.PARAMETER AppGwNameResourceGroup

Resource Group of Application Gateway to be queried.

.EXAMPLE

./Update-IPRestriction.ps1 `
-AzureClientId $AzureClientId `
-AzureClientSecret $AzureClientSecret `
-AzureTenantId $AzureTenantId `
-AzureSubscriptionId $AzureSubscriptionId `
-ResourceGroupName '<webapp's RG name>' `
-WebAppName '<import-frontend-test>' `
-AppGwName '<ApplicationGatewayName>' `
-AppGwResourceGroup '<App Gw RG name>'

#>
[CmdletBinding()]
  param(
    [string]$AzureClientId,
    [string]$AzureClientSecret,
    [string]$AzureTenantId,
    [string]$AzureSubscriptionId,
    [string]$ResourceGroupName,
    [string]$WebAppName,
    [string]$AppGwName,
    [string]$AppGwResourceGroup
  )
  #form a credential object from clientId and Secret
  $Cred = New-Object -TypeName System.Management.Automation.PSCredential ($AzureClientId, ($AzureClientSecret | ConvertTo-SecureString -AsPlainText -Force))

  function AzureLogin{
    param(
      [System.Management.Automation.PSCredential]$Credential,
      [string]$TenantId,
      [string]$SubscriptionId
    )
    Login-AzureRmAccount `
    -Credential $Credential `
    -TenantId $TenantId `
    -Subscription $SubscriptionId `
    -ServicePrincipal
  }

  AzureLogin -Credential $Cred -TenantId $AzureTenantId -SubscriptionId $AzureSubscriptionId

  #get AppGw public IP resourceID
  $AppGwPublicIpId = (Get-AzureRmApplicationGateway `
  -Name $AppGwName `
  -ResourceGroupName $AppGwResourceGroup).FrontendIPConfigurations.PublicIPAddress |
  select -ExpandProperty Id

  Write-Verbose "Application Gateway $AppGwNAme's public IP ID is: $AppGwPublicIpId"

  #get AppGw Public Ip by resource Id
  $AppGwPublicIpAddress = (Get-AzureRmResource -ResourceId $AppGwPublicIpId).Properties.ipAddress

  #add that Ip to Ip restriction to set app service
  $WebApp = (Get-AzureRmResource `
  -ResourceGroupName $ResourceGroupName `
  -ResourceType Microsoft.Web/sites/config `
  -ResourceName $WebAppName/web `
  -ApiVersion 2016-08-01)
  
  Write-Verbose "Current IP restriction is: `n$($WebApp.Properties.ipSecurityRestrictions | Out-String)"

  #this only works if there is just one ip in restriction, if we need more then some more logic will be needed
  if ( $AppGwPublicIpAddress -ne $WebApp.Properties.ipSecurityRestrictions.ipAddress ) {

    Write-Host "[INFO] IP restriction `n$($WebApp.Properties.ipSecurityRestrictions.ipAddress) `nis different. Updating . . ."

    $WebApp.Properties.ipSecurityRestrictions = @(
      @{
        "ipAddress"   = "$AppGwPublicIpAddress"
        "subnetMask"  = "255.255.255.255"
        "action"      = "Allow"
        "priority"    = "60"
      }
    )

    Write-Debug "Properties are:"

    Write-Verbose "WebApp $WebAppName's IP restriction will be: `n$($WebApp.Properties.ipSecurityRestrictions | Out-String)"

    #apply changes
    Set-AzureRmResource `
    -ResourceId $WebApp.ResourceId `
    -Properties $WebApp.Properties `
    -ApiVersion 2016-08-01 `
    -Force
  }
  else {
    Write-Host "[INFO] IP Restriction on app $WebAppName is the same, no need to update."
  }

  Logout-AzureRmAccount





