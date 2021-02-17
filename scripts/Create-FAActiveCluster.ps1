<#
Create-FAActiveCluster.ps1

: Revision 1.0.0.0
:: initial release

Example script to create a FlashArray ActiveCluster configuration.
This is not intended to be a complete run script. It is for example purposes only.
Variables should be modified to suit the environment.

This script is AS-IS. No warranties expressed or implied by Pure Storage or the creator.

Requirements:
  Pure Storage PowerShell SDK v1 module
  Flasharray array admin login credentials
#>
#
### Start
## Define variables
$array1Endpoint = '10.1.1.1'
$array2Endpoint = '10.1.1.2'
$podName = "pod1"
$host1name = "HostA"
$host2Name = "HostB"
$hostgroupName = "hostgroup1"
$volumeName = "pod::vol1"
$volumeUnit = "T"
$volSize = "1"

## Connect to arrays.
$array1 = New-PfaArray -EndPoint $array1Endpoint -Credentials (Get-Credential) -IgnoreCertificateError
$array2 = New-PfaArray -EndPoint $array2Endpoint -Credentials (Get-Credential) -IgnoreCertificateError

## Retrieve connection key for array2.
$keyString = Get-PfaConnectionKey -Array $Array2

## Retrieve replibond IP address.
$replAddress = (Get-PfaNetworkInterfaces -Array $array1 | Where-Object Name -EQ "replbond").address

## Create Pod replication connection.
New-PfaReplicationConnection -Array $Array -ManagementAddress $array2Endpoint -ReplicationAddress $replAddress -ConnectionKey $keyString -Types "replication"
# Alternative command
# Invoke-Pfa2CLICommand -CommandText "purearray connect --type sync-replication" -Credential (Get-Credential) -EndPoint $array1Endpoint

## Create stretched Pod.
New-PfaPod -Array $array1 -Name $podName

## Create a volume for the Pod.
New-PfaVolume –Array $array1 –VolumeName $volumeName –Unit $volumeUnit –Size $volSize

## Add the volume (must be done before Stretching).
Add-PfaVolumeToContainer -Array $array1 -Name $volumeName -Container $podName

# Stretch the Pod to Array 2 and set failover preference.
Add-PfaArrayToPod -Array $array1 -PodName $podName -ArrayName $array2Endpoint
Set-PfaPod -Array $array1 -FailoverPreference $array1Endpoint -Name $podName

## Connect hosts.
New-PfaHost -Array $array1 -PreferredArrays $array1 -Name $host1name
New-PfaHost -Array $array1 -PreferredArrays $array2 -Name $host2Name
New-PfaHost -Array $array2 -PreferredArrays $array1 -Name $host1name
New-PfaHost -Array $array2 -PreferredArrays $array2 -Name $host2name

## For ESXi set the personality on the Hosts.
Set-PfaPersonality -Array $array1 -Name $host1name -Personality esxi
Set-PfaPersonality -Array $array1 -Name $host2name -Personality esxi
Set-PfaPersonality -Array $array2 -Name $host1name -Personality esxi
Set-PfaPersonality -Array $array2 -Name $host2name -Personality esxi

## Create Host group.
New-PfaHostGroup -Array $array1 -Hosts $host1name, $host2Name -Name $hostgroupName

## Connect Pod volume to Host group.
New-PfaHostGroupVolumeConnection -HostGroupName $hostgroupName -VolumeName $podVol

### END
