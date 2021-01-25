#
# Example script to create Offload Target to Azure Storage Account on FlashArray for Purity CloudSnap.
# This is not intended to be a complete run script. It is for example purposes only.
# You are free to use any portion without license.
#
# This script is AS-IS. No warranties expressed or implied by Pure Storage or the author.
#
# verify requirements
try {
    Write-Host "Checking for elevated permissions..."
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
                [Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again."
        Break
    }
    else {
        Write-Host "Cmdlet is running as administrator. Continuing..." -ForegroundColor Green
    }

    ## Check for modules
    Write-Host "Checking, installing, and importing prerequisite modules."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $modulesArray = @(
        "Az",
        "PurePowerShellSDK2"
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
    catch {
        Write-Host "There was an problem verifying requirements. Please try again or submit an Issue in the GitHub Repository."
    }
}
## Begin Azure work
# Connect to your account
Connect-AzAccount

# Please uncomment and edit if you require switcing subscription context
# Get-AzContext
# Set-AzContext -Subscription <subscrptionID_or_name>

# Change resource group variable to suit
$resourceGroup = "storage-resource-group"
$location = "westus"
$sAccountName = "MyStorageAccount"  # Change to suit
$OTName = "azuretarget" # Change to suit

# Create the resource group
New-AzResourceGroup -Name $resourceGroup -Location $location

# Create the storage account
$sAccount = New-AzStorageAccount -ResourceGroupName $resourceGroup -Name $sAccountName -Location $location -SkuName Standard_RAGRS -Kind StorageV2

# Uncomment to create specific container if necessary (refer to Purity CloudSnap Best Practices Guide for more infromation)
#$sContainername = "MyContainer" # Change to suit
#New-AzStorageContainer -Name sContainerName -Permission Container

# Obtain Access key and store in variable
$sAccessKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -AccountName sAccountName) | Where-Object { $_.KeyName -eq "key1" }

## Begin FlashArray work
# Connect to FlashArray
# There are a few ways to connect to a FlashArray with API version 2.2 and later. if your array is API version 2.0 or 2.1, you must use OAuth to connect.
# To determine which API your array supports, go to https://<FQDN_or_IP_address_of_Array>/api/api_version
# You can find more infromation on connecting to the arrays by visting https://support.purestorage.com/Solutions/Microsoft_Platform_Guide and clicking on Windows PowerShell.
# To connect via an API token (API version 2.2 or later), define the $username and $password variables (or use Get-Credential), and use the following line
Connect-Pfa2Array -Endpoint $array -Username $Username -Password $Password -IgnoreCertificateError
# To connect via Oauth (API version 2.0 or 2.1), define the necessary variables and use the following function and command
#function ArrayAuth () {
#    $global:fa = New-Pfa2ArrayAuth -MaxRole array_admin -Endpoint $arrayEndpoint -APIClientName $ArrayClientname -Issuer $ArrayIssuer -Username $Username -Password #$Password
#    $global:clientId = $fa.PureClientApiClientInfo.clientId
#    Write-Host "ClientID: $($clientId)"
#    Write-Host " "
#    $global:keyId = $fa.PureClientApiClientInfo.KeyId
#    Write-Host "KeyID $($KeyId)"
#    Write-Host " "
#    $global:privateKeyFile = $fa.pureCertInfo.privateKeyFile
#    Write-Host "PrivateKey $($privateKeyFile)"
#}
#ArrayAuth
#$array = Connect-Pfa2Array -Endpoint $arrayEndpoint -Username $Username -Issuer $ArrayIssuer -ClientId $clientId -KeyId $keyId -PrivateKeyFile $privateKeyFile -PrivateKeyPassword $privateKeyPass -IgnoreCertificateError -ApiClientName $ArrayClientname



# Create the Offload Target.
# Add -ContainerName parameter if a container was specified above
$azureOffload = New-Pfa2OffloadAzureObject -AccountName $sAccount -SecretAccessKey $sAccessKey
New-Pfa2Offload -Array $array -Name $OTName -Azure $azureOffload -Initialize

# END