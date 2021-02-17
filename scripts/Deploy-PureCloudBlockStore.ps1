<#
Deploy-PureCloudBlockStore.ps1

: Revision 1.0.0.0
:: initial release

Example script to deploy an instance of Pure Cloud Block Store via an ARM template in Azure.
This is not intended to be a complete run script. It is for example purposes only.
Variables should be modified to suit the environment.

This script is AS-IS. No warranties expressed or implied by Pure Storage or the creator.

Requirements:
  Azure Az Module
#>

### Start
## Define variables
$azSubscription = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$resourceGroup = "cloudblockstore-rg"
$location = "westus2"
## Optional. Name the deployment based on the date for future reference.
$today = Get-Date -Format "MM-dd-yyyy"
$deploymentName = "PureCBSDeployment" + "$today"

## Verify requirements.
try {
    Write-Host "Checking for elevated permissions..."
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again."
        Break
    }
    else {
        Write-Host "Script is running as administrator. Continuing..." -ForegroundColor Green
    }

    # Check for modules
    Write-Host "Checking, installing, and importing prerequisite modules..."
    Write-Host "If the Az module has not been previously installed, this will take some time."
    Write-Host "If prompted to enable Nuget, please accept."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $modulesArray = @(
        "Az"
    )
    ForEach ($mod in $modulesArray) {
        If (Get-Module -ListAvailable $mod) {
            Continue
        }
        Else {
            Install-Module $mod -Force -AllowClober -ErrorAction 'SilentlyContinue'
            Import-Module $mod -ErrorAction 'SilentlyContinue'
        }
    }
}
    catch {
        Write-Host "There was an problem verifying the requirements. Please try again or submit an Issue in the GitHub Repository."
    }
#

## Connect to Azure
Connect-AzAccount
# Please uncomment and edit if you require switching subscription context which would be necessary if you have access to multiple subscriptions.
# Get-AzContext
# Set-AzContext -Subscription <subscrptionID_or_name>

# Create the resource group or comment out if already exists.
# The resource group must exist before deployment.
New-AzResourceGroup -Name $resourceGroup -Location $location

## Perform the deployment.
New-AzResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroup -TemplateFile 'cbs_templatefile.json' -TemplateParameterFile 'cbs_parameterfile.json'

<# The Pure Cloud Block Store can also be deplyed using the Azure CLI via a local session or a Cloud Shell session (preferred)
Use these lines to perform the deployment. refer to this article for more complete instructions - https://support.purestorage.com/FlashArray/PurityFA/Cloud_Block_Store/Cloud_Block_Store_Deployment_and_Configuration_Guide_for_Azure_using_Azure_CLI
az account set --subscription $azSubscription
az deployment group create --resource-group $resourceGroup --template-file cbs_templatefile.json --parameters cbs_parameterfile.json
#>

### END