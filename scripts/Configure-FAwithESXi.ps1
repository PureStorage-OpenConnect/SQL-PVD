# Configure-FAwithESXi.ps1
#
# : Revision 1.0.0.0
# :: initial release
#
# Example script to configure a FlashArray for ESXi hosts with personaility, host group, pod, and volumes.
# This is not intended to be a complete run script. It is for example purposes only.
# Variables should be modified to suit the environment.
#
# This script is AS-IS. No warranties expressed or implied by Pure Storage or the author.
#
# Requirements:
#  Pure Storage PowerShell SDK v1 module
#  VMware vSphere PowerCLI (Only required to obtain WWNs from HBAs on ESXi hosts. You can also enter these manually.)
#  Flasharray array admin login credentials
#
#
#### Start
## Define variables
$vcenter = "vcenter1"
$ESXiCluster = "Cluster1"
$esxiHost1Name = "esxi1"
$esxiHost2Name = "esxi2"
$array1Endpoint = "10.1.1.1"
$array2Endpoint = "10.11.1.2"
$podName = "pod1"
$hostgroupName = "ESXiHosts"
$volumeName = "vol1"
$volSize = "1"
$volUnit = "TB"

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
    Write-Host "If the PowerCLI module has not been previously installed, this will take some time."
    Write-Host "If prompted to enable Nuget, please accept."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $modulesArray = @(
        "PureStoragePowerShellSDK"
        "VMware.PowerCLI"
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

## Obtain WWNs from ESXi hosts
Connect-VIServer​​ $vcenter -Credential​​ (Get-Credential)
$wwn1 = Get-VMHostHba​​ -VMHost​​ $esxiHost1Name​​ -Type​​ FibreChannel
$wwn2 = Get-VMHostHba​​ -VMHost​​ $esxiHost1Name​​ -Type​​ FibreChannel
foreach ($wwn in $wwn1)   {
    $wwpn1 =​​ "{0:x}"​​ -f​​ $hba.PortWorldWideName
}
foreach ($wwn in $wwn2)   {
    $wwpn2 =​​ "{0:x}"​​ -f​​ $hba.PortWorldWideName
}
# Disconnect from vCenter
Disconnect-VIServer $vcenter

## Connect to FlashArray
# We need to connect to the array at this point to connect the hosts and get iSCSI info from the array. While were here, create the Host Group.
# There are several ways to connect to a FlashArray. please refer to the Powershell SDK documentation at https://support.purestorage.com.
# The method below will prompt for the user name and password for the array.
$array = New-PfaArray -EndPoint $arrayEndpoint -Credentials (Get-Credential) -IgnoreCertificateError
# This method will use pre-defined variables (not stated in this example script) for the credentials.
# Connect-Pfa2Array -Endpoint $array -Username $Username -Password $Password -IgnoreCertificateError

## Create hosts in FlashArray
## Create the hosts and host group
foreach ($wwn in $wwpn1) {
New-PfaHost –Array $array –Name $esxiHost1Name –WwnList $wwn
}
foreach ($wwn in $wwpn2) {
New-PfaHost –Array $array –Name $esxiHost2Name –WwnList $wwn
}
New-PfaHostGroup -Array $array -Hosts $esxiHost1Name, $esxiHost2Name -Name $hostgroupName

## Set host personality
Set-PfaPersonality -Array $array -Name $esxiHost1Name -Personality ESXi
Set-PfaPersonality -Array $array -Name $esxiHost2Name -Personality ESXi

## Create a volume on ESXi Host 1
New-PfaVolume –Array $array –VolumeName $volumeName –Unit $volUnit –Size $volSize

## Create a Pod, Add the volume (must be done before Stretching)
New-PfaPod -Array $array -Name $podName
Move-PfaVolumeOrSnapshot -Array $array -Name $volumeName -Container $podName

# Stretch the Pod to Array 2 and set failover preference
Add-PfaArrayToPod -Array $array -PodName $podName -ArrayName $array2Endpoint
Set-PfaPod -Array $array -FailoverPreference $array1Endpoint -Name $podName

### END


