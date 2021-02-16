#
# Create-AsyncReplicationWithCBS.ps1
#
$array1 = ''
$array2 = ''
$array = New-PfaArray -EndPoint $array1 -Credentials (Get-Credential) -IgnoreCertificateError
New-PfaReplicationConnection -Array $Array -ReplicationAddress $array1 -ConnectionKey $KeyString -ManagementAddress $array2 -Types Replication