#
# Create-ArrayReplication.ps1
#
# : Revision 1.0.0.0
# :: initial release
#
# Example script to create replication connection between two FlashArrays (on-premises or Cloud Block Store).
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
$array1 = '10.1.1.1'
$array2 = '10.1.1.2'
$array1 = New-PfaArray -EndPoint $array1 -Credentials (Get-Credential) -IgnoreCertificateError
$array2 = New-PfaArray -EndPoint $array2 -Credentials (Get-Credential) -IgnoreCertificateError
# retrieve connection key
$KeyString = Get-PfaConnectionKey -Array $Array2
$replAddress = (Get-PfaNetworkInterfaces -Array $array1 | Where-Object Name -eq "replbond").address
New-PfaReplicationConnection -Array $Array1 -ReplicationAddress $replAddress -ConnectionKey $KeyString -ManagementAddress $array2 -Types Replication
# verify replication
Get-PfaArrayTCPConnection -Array $array1
#### END