<#
New-OffloadTargetSnapshot.ps1

: Revision 1.0.0.0
:: initial release

Example script to create an Offload Target and update a snapshot offload target from a FlashArray pod.
This script will clone the pod, clone volumes from the cloned pod into a protection group,
take a snapshot of that protection group, and replicate changes to the offload target.

This script is provided AS-IS. No warranties expressed or implied by Pure Storage or the creator.

Requirements:
  PowerShell version 5.1
  Pure Storage PowerShell SDK v1 module
  Pure Storage PowerShell SDK v2 module
  Flasharray array admin login credentials
#>
## Define variables
$Credential = (Get-Credential)
$Pod = "pod1"
$ArrayClientname = "myClient"
$Target = "array1"
$ArrayEndpoint = "IP address x.x.x.x"
<# You may uncomment this to use the script command line parameters instead of defining variables.
Param (
    [Parameter(Mandatory = $true)][PSCredential]$Credential,
    [Parameter(Mandatory = $true)][String]$Pod,
    [Parameter(Mandatory = $true)][String]$ArrayClientname,
    [Parameter(Mandatory = $true)][String]$Target,
    [Parameter(Mandatory = $true)][String]$ArrayEndpoint
)
#>

## Verify requirements
#Requires -Version 5.1
"Running PowerShell $($PSVersionTable.PSVersion)."
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
    Write-Host "If prompted to enable Nuget, please accept."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $modulesArray = @(
        "PureStoragePowerShellSDK",
        "PureStoragePowerShellSDK2"
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

### End Verify Requirements

$ArrayIssuer = $ArrayClientname
$ArrayPassword = $Credential.Password
$ArrayUsername = $Credential.UserName

$suffix = "-async"

$DebugPreference = "Continue"
$ErrorActionPreference = "Stop"

function cleanup-tempPod {
    [Parameter(Mandatory = $true)][String] $clonedPodName

    $clonedPod = Get-Pfa2Pod -name $clonedPodName -ErrorAction SilentlyContinue

    if ($clonedPod.count -eq 1){
        $debugstring = "Cloned pod " + $clonedPodName + " already exists. Cleaning it up."
        # Destroy & eradicate each volume in the cloned Pod
        Write-Debug $debugstring
        $vols = Get-Pfa2Volume | Where-Object {$_.Pod.Name -eq $clonedPodName}
        $debugstring = "Destroying " + $vols.count + " volumes in cloned pod"
        write-debug $debugstring
        foreach ($vol in $vols){
            write-debug $vol.name
            Remove-Pfa2Volume -name $vol.name
            Remove-Pfa2Volume -eradicate -name $vol.name -Confirm:$false
        }
        # Destroy & eradicate each PGroup in the cloned Pod
        $pgs = Get-Pfa2ProtectionGroup | Where-Object {$_.Pod.Name -eq $clonedPodName}
        $debugstring = "Destroying " + $pgs.count + " protection groups in cloned pod"
        write-debug $debugstring
        foreach ($pg in $pgs){
            write-debug $pg.name
            Remove-Pfa2ProtectionGroup -name $pg.name
            Remove-Pfa2ProtectionGroup -eradicate -name $pg.name -Confirm:$false
        }
        # Destroy & eradicate the cloned Pod itself
        $debugstring = "Destroying pod " + $clonedPodName
        write-debug $debugstring
        Remove-Pfa2Pod -name $clonedPodName
        Remove-Pfa2Pod -name $clonedPodName -Eradicate -Confirm:$false
    }

    else{
        $debugstring = "Cloned pod " + $clonedPodName + " does not already exist."
        Write-Debug $debugstring
    }
    Write-Debug "Cleanup of existing Cloned Pod Complete"
    return
}

## Get Connected
Write-Debug "Connecting with Pure PowerShell SDK v1"
try{
    $faSDK1 = New-PfaArray -Credentials $Credential -Endpoint $ArrayEndpoint -IgnoreCertificateError
}

catch {
    write-debug "Could not establish array connection. Exiting"
    break
}

Write-Debug "Connecting with Pure PowerShell SDK v2"
try{
    $auth = New-Pfa2ArrayAuth -MaxRole 'array_admin' -Endpoint $ArrayEndpoint -APIClientName $ArrayClientname -Issuer $ArrayIssuer -Username $ArrayUsername -Password $ArrayPassword -Force
    $clientId = $auth.PureClientApiClientInfo.clientId
    $keyId = $auth.PureClientApiClientInfo.KeyId
    $privateKeyFile = $auth.pureCertInfo.privateKeyFile
    $faSDK2 = Connect-Pfa2Array -Endpoint $ArrayEndpoint -Username $ArrayUsername -Issuer $ArrayIssuer -ClientId $clientId -KeyId $keyId -PrivateKeyFile $privateKeyFile -IgnoreCertificateError -ApiClientName $ArrayClientname
}

catch {
    write-debug "Could not establish array connection. Exiting"
    break
}

## Make sure Pod exists
$debugstring = "Checking for existence of pod: " + $pod
Write-Debug $debugstring

$existingPod = Get-Pfa2Pod -name $pod -ErrorAction SilentlyContinue
if ($existingPod.count -eq 1){
    $debugstring = "Pod " + $pod + " exists."
    Write-Debug $debugstring
}
else{
    $debugstring = "Pod " + $pod + " does not exist. Exiting."
    Write-Debug $debugstring
    break
}

## Get Offload Target
Write-Debug "Getting Offload Target"
$offloads = Get-Pfa2Offload | Where-Object name -eq $target
$debugstring = "There are " + $offloads.count + " offloads found matching " + $target + "."
write-debug $debugstring
foreach ($offload in $offloads){
    if ($offload.status -eq "connected"){
        $outputstring = $offload.name + " is currently connected."
        write-debug $outputstring
    }
    else{
        $outputstring = $offload.name + " is found but not currently connected. Exiting"
        write-debug $outputstring
        break
    }
}

## Check for existence of PGroup
$pgroupname = $pod + $suffix
$debugstring = "Checking for the existence of Protection Group: " + $pgroupname
write-debug $debugstring
$pgroup = Get-Pfa2ProtectionGroup -name $pgroupname -ErrorAction SilentlyContinue

## If PGroup Exists, make sure Target is configured
if ($pgroup.count -eq 1){
    $debugstring = $pgroupname + " exists."
    write-debug $debugstring

    $existingTarget = Get-Pfa2ProtectionGroupTarget -GroupNames $pgroupname -MemberNames $target
    if ($existingTarget.count -eq 1){
        $debugstring = "Found target " + $target + " in PGroup " + $pgroupname
        write-debug $debugstring
    }
    else{
        $debugstring = "Adding target " + $target + " to Protection Group " + $pgroupname
        Write-Debug $debugstring
        $newpgroupTarget = New-Pfa2ProtectionGroupTarget -GroupNames $pgroupname -MemberNames $target
    }
}

## If PGroup does not exist, create it and add the Target
else{
    $debugstring = "Protection Group " + $pgroupname + " does not exist. Creating it."
    Write-Debug $debugstring
    $newpgroup = New-Pfa2ProtectionGroup -name $pgroupname
    $debugstring = "Adding target " + $target + " to Protection Group " + $pgroupname
    Write-Debug $debugstring
    $newpgroupTarget = New-Pfa2ProtectionGroupTarget -GroupNames $pgroupname -MemberNames $target
}

## TODO: Check If Transfer Is Already In Progress and Abort if So

## Cloned Pod Cleanup in preparation for new cloned Pod (in case it exists already)
$clonedPodName = $pod + $suffix
write-debug "Calling Cleanup function"
cleanup-tempPod -clonedPodName $clonedPodName

## Create a temporary Pod Clone
$podref = New-Pfa2ReferenceObject -name $pod
$debugstring = "Cloning Pod " + $pod + " as " + $clonedPodName
Write-Debug $debugstring
$clonedPod = New-Pfa2Pod -name $clonedPodName -Source $podref

## Copy Volumes from the cloned Pod to the external PGroup
$debugstring = "Copying Volumes from cloned Pod " + $clonedPodName + " to PGroup " + $pgroupname
Write-Debug $debugstring
$fullVolList = Get-Pfa2Volume
$vols = $fullVolList | Where-Object {$_.Pod.Name -eq $clonedPodName}
$debugstring = $clonedPodName + " volume count: " + $vols.count
write-debug $debugstring
foreach ($vol in $vols){
    $newVolName = $vol.name.split("::")[2] + $suffix
    $volref = New-Pfa2ReferenceObject -name $vol.name
    $debugstring = "Old volume name: " + $vol.name + " New volume name: " + $newVolName
    Write-Debug $debugstring

    if($($fullVolList | Where-Object name -eq $newVolName).count -eq 0){
        $debugstring = "Creating volume " + $newVolName
        Write-Debug $debugstring
        $newvol = New-Pfa2Volume -Name $newVolName -Provisioned $vol.Provisioned -Source $volref
    }
    else{
        $debugstring = "Volume " + $newVolName + " exists. Overwriting."
        Write-Debug $debugstring
        $newvol = New-Pfa2Volume -Name $newVolName -Provisioned $vol.Provisioned -Source $volref -Overwrite $true
    }
    $addToPgroup = New-Pfa2ProtectionGroupVolume -GroupNames $pgroupname -MemberNames $newVolName
    # Get rid of unnecessary overwrite snapshots
    write-debug "Removing overwrite snapshots"
    Get-Pfa2VolumeSnapshot | Where-Object {$_.TimeRemaining -gt 0 -and $_.Source.Name -eq $newVolName} | Remove-Pfa2VolumeSnapshot -Eradicate -Confirm:$false
}

## Cloned Pod Cleanup (Again)
$clonedPodName = $pod + $suffix
write-debug "Calling Cleanup function"
cleanup-tempPod -clonedPodName $clonedPodName

## Create a PGroup Snapshot and replicate it now
$newsnap = New-PfaProtectionGroupSnapshot -array $faSDK1 -Protectiongroupname $pgroupname -ReplicateNow -ApplyRetention
return $newsnap
