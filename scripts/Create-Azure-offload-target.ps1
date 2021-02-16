# Create-Azure-offload-target.ps1
#
# : Revision 1.1.0.0
# :: Restructured for SDK [mnelson]
# : Revision 1.0.0.0
# :: Inital revision
#
# Example script to create Offload Target to Azure Storage Account on FlashArray for Purity CloudSnap.
# This is not intended to be a complete run script. It is for example purposes only.
# Variables should be modified to suit the environment.
#
# This script is AS-IS. No warranties expressed or implied by Pure Storage or the author.
#
# Requirements:
#  Azure Az module
#  Pure Storage PowerShell SDK v1 module
#  Flasharray array adminlogin credentials
#
### Start
# Change variables to suit
$OTName = "AzureBlob"
$AZStorageAccount = "flasharraystorage" # Must be unique
$azureContainerName = "offload"
$resourceGroup = "FlashArrayoffload-rg" # Change to suit
$location = "westus2" # Change to suit
$arrayEndpoint = "10.1.1.1"

## Verify requirements
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
        "Az",
        "PureStoragePowerShellSDK"
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

## Begin Azure
# Local Powershell session
# Connect to your account
Connect-AzAccount

# Please uncomment and edit if you require switching subscription context which would be necessary if you have access to multiple subscriptions.
# Get-AzContext
# Set-AzContext -Subscription <subscrptionID_or_name>

# Create the resource group or comment out if already exists
New-AzResourceGroup -Name $resourceGroup -Location $location

# Create the storage account
$AzAccount = New-AzStorageAccount -ResourceGroupName $resourceGroup -Name $AZStorageAccount -Location $location -SkuName Standard_LRS -Kind StorageV2

# Uncomment to create specific container if necessary (refer to Purity CloudSnap Best Practices Guide for more infromation)
#$sContainername = "MyContainer" # Change to suit
#New-AzStorageContainer -Name sContainerName -Permission Container

# Obtain Access key and store in variable
$secretKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -Name $AZStorageAccount).Value[0]

## Begin FlashArray
# Connect to FlashArray
# There are several ways to connect to a FlashArray. please refer to the Powershell SDK documentation at https://support.purestorage.com.
# The method below will prompt for the user name and password for the array.
$array = New-PfaArray -EndPoint $arrayEndpoint -Credentials (Get-Credential) -IgnoreCertificateError
# This method will use pre-defined variables (not stated in this example script) for the credentials.
# Connect-Pfa2Array -Endpoint $array -Username $Username -Password $Password -IgnoreCertificateError

# Create the Offload Target.
# Add -ContainerName parameter if a container was specified above. Otherwise the defualt name is "offload".
Connect-PfaOffloadAzureTarget -Array $array -Name $OTName -AccountName $AzStorageAccount -SecretAccessKey $secretKey -ContainerName $azureContainerName -Initialize $True

### END