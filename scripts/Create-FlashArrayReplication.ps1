<#
Create-FlashArrayReplication.ps1

: Revision 1.0.0.0
:: initial release

Example script to create replication connection between two FlashArrays (on-premises or Cloud Block Store).
This is not intended to be a complete run script. It is for example purposes only.
Variables should be modified to suit the environment.

This script is AS-IS. No warranties expressed or implied by Pure Storage or the creator.

Requirements:
  Pure Storage PowerShell SDK v1 module
  Flasharray array admin login credentials
#>
#
### Start
## Define Variables.
$array1 = '169.254.0.1'
$array2 = '169.254.0.2'
$array1 = New-PfaArray -EndPoint $array1 -Credentials (Get-Credential) -IgnoreCertificateError
$array2 = New-PfaArray -EndPoint $array2 -Credentials (Get-Credential) -IgnoreCertificateError

## Retrieve connection key.
$KeyString = Get-PfaConnectionKey -Array $Array2

## Retrieve replibond IP address.
$replAddress = (Get-PfaNetworkInterfaces -Array $array1 | Where-Object Name -eq "replbond").address

## Create array replication.
New-PfaReplicationConnection -Array $Array1 -ReplicationAddress $replAddress -ConnectionKey $KeyString -ManagementAddress $array2 -Types Replication

## Verify replication.
Get-PfaArrayTCPConnection -Array $array1

### END