# Create-SSMS-Backups.ps1
#
# : Revision 1.0.0.0
# :: initial release
#
# Example script to create and restore application consistent database backups using the Pure storage SSMS extension and VSS provider.
# This is not intended to be a complete run script. It is for example purposes only.
# Variables should be modified to suit the environment.
#
# This script is AS-IS. No warranties expressed or implied by Pure Storage or the author.
#
# Requirements:
#  SQL administrative login
#  Pure Storage SSMS Extension (with VSS and Backup SDK module included)
#  Flasharray array admin login credentials
#
#
## START

#Create Computer Credential
Add-PfaBackupCred -CredentialName WinHost1 -Address 10.21.190.72 -CredentialType Windows -Credential (Get-Credential)

#Create FlashArray Credential
Add-PfaBackupCred -CredentialName FlashArray1 -Address 10.21.190.110 -CredentialType FlashArray -Credential (Get-Credential)

#Create vCenter Credential
Add-PfaBackupCred -CredentialName vCenter1 -Address 10.21.190.50 -CredentialType vCenter -Credential (Get-Credential)

#Create a backup job. Component is the database name. Computername should be a created computer credential for the SQLFCI network name in the event of a failoverclusterinstance.
Add-PfaBackupJob -ConfigName ConfigFCI1 -ComputerName SQLFCI1 -FAName FlashArray1 -VCenterName vCenter1 -VMName SQLFCI1VM1 -Component hammerdb -CopyOnly:$false -MetadataDir c:\mymetadata

#create a backup
Invoke-PfaBackupJob -ConfigName ConfigFCI1

#mount a backup to management host outside of FCI
Mount-PfaBackupJob -HistoryId 29 -DriveLetter N: -MountComputer jump-1 -MountVMName jump-1

#dismount a backup from the management host
Dismount-PfaDrive -HistoryId 29

#restore a backup
Restore-PfaBackupJob -HistoryId 31

#Optional, but when only in PowerShell, you may have to enumerate things to properly specify the saved credentials to create a configuration.
# List the already existing, saved credentials
Get-PfaBackupCredList -CredentialType Windows
Get-PfaBackupCredList -CredentialType vCenter
Get-PfaBackupCredList -CredentialType FlashArray

#list backup history. Backup historyid must be specified for restore, mount, dismount
Get-PfaBackupHistory

#install the vss provider. Usually handled automatically and checked during a backup attempt. If however, you add a computer credential, but attempt to mount a snapshot to it before running a backup, it will not have the provider. If it has an older version of the provider, the service will be running, and this command will fail without -forceupgrade

Install-VSS -ComputerName jump-1 -ForceUpgrade

## END