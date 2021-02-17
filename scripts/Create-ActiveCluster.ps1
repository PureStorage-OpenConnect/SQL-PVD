# Create-ActiveCluster.ps1
#
# : Revision 1.0.0.0
# :: initial release
#
# Example script to create a FlashArray ActiveCluster configuration.
# This is not intended to be a complete run script. It is for example purposes only.
# Variables should be modified to suit the environment.
#
# This script is AS-IS. No warranties expressed or implied by Pure Storage or the author.
#
# Requirements:
#  Pure Storage PowerShell SDK v1 module
#  Flasharray array admin login credentials
#
#
#### Start
## Define variables
$array1 = '10.1.1.1'
$array2 = '10.1.1.2'
$array1 = New-PfaArray -EndPoint $array1 -Credentials (Get-Credential) -IgnoreCertificateError
$array2 = New-PfaArray -EndPoint $array2 -Credentials (Get-Credential) -IgnoreCertificateError
# retrieve connection key
$KeyString = Get-PfaConnectionKey -Array $Array2
$replAddress = (Get-PfaNetworkInterfaces -Array $array1 | Where-Object Name -EQ "replbond").address


### Q Notes:
<##
$Array = New-pfaArray -EndPoint "10.21.231.28" -IgnoreCertificateError -Credentials (Get-Credential)
$TargetArray = New-pfaArray -EndPoint "10.21.231.24" -IgnoreCertificateError -Credentials (Get-Credential)
$connectionKey = Get-PfaConnectionKey -Array $TargetArray
New-PfaReplicationConnection -Array $Array -ManagementAddress "10.21.231.24" -ReplicationAddress "10.21.89.95" -ConnectionKey $connectionKey.connection_key -Types "replication"
#>
