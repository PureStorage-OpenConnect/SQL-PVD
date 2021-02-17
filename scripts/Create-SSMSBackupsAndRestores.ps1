<#
Create-SSMSBackupsAndRestores.ps1

: Revision 1.0.0.0
:: initial release

Example script to create and restore application consistent database backups using the Pure storage SSMS extension and VSS provider.
This is not intended to be a complete run script. It is for example purposes only.
Variables should be modified to suit the environment.

This script is AS-IS. No warranties expressed or implied by Pure Storage or the creator.

Requirements:
  SQL administrative login
  Pure Storage SSMS Extension (with VSS and Backup SDK module included)
  Flasharray array admin login credentials
#>
#
### START
## Define variables
$hostName = "HostA"
$winEndpoint = "169.254.0.1"
$arrayEndpoint = "169.254.0.2"
$vcenterEndpoint = "169.254.0.3"

## Verify requirements.
try {
    Write-Host "Checking for elevated permissions..."
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again."
        Break
    }
    else {
        Write-Host "Script is running as administrator. Continuing..." -ForegroundColor Green
    }
}
catch {
    Write-Host "There was an problem verifying the requirements. Please try again or submit an Issue in the GitHub Repository."
}
#

## Create Computer Credential.
Add-PfaBackupCred -CredentialName WinHost1 -Address $winEndpoint -CredentialType Windows -Credential (Get-Credential)

## Create FlashArray Credential.
Add-PfaBackupCred -CredentialName FlashArray1 -Address $arrayEndpoint -CredentialType FlashArray -Credential (Get-Credential)

## Create vCenter Credential.
Add-PfaBackupCred -CredentialName vCenter1 -Address $vcenterEndpoint -CredentialType vCenter -Credential (Get-Credential)

## Create a backup job. 'Component' is the database name. 'Computername' should be a created computer credential for the SQLFCI network name in the event of a FCI.
Add-PfaBackupJob -ConfigName ConfigFCI1 -ComputerName SQLFCI1 -FAName FlashArray1 -VCenterName vCenter1 -VMName SQLFCI1VM1 -Component hammerdb -CopyOnly:$false -MetadataDir c:\mymetadata

## Create a backup.
Invoke-PfaBackupJob -ConfigName ConfigFCI1

## Mount a backup to management host outside of FCI.
Mount-PfaBackupJob -HistoryId 29 -DriveLetter N: -MountComputer $hostname -MountVMName $hostName

## Dismount a backup from the management host.
Dismount-PfaDrive -HistoryId 29

## Restore a backup.
Restore-PfaBackupJob -HistoryId 31

## Optional, but when only in PowerShell, you may have to enumerate things to properly specify the saved credentials to create a configuration.
# List the already existing, saved credentials.
Get-PfaBackupCredList -CredentialType Windows
Get-PfaBackupCredList -CredentialType vCenter
Get-PfaBackupCredList -CredentialType FlashArray

## List backup history. Backup historyid must be specified for restore, mount, dismount.
Get-PfaBackupHistory

## Install the vss provider. This is usually handled automatically and checked during a backup attempt. If however, you add a computer credential, but attempt to mount a snapshot to it before running a backup, it will not have the provider. If it has an older version of the provider, the service will be running, and this command will fail without the '-ForceUpgrade' parameter.

Install-VSS -ComputerName $hostName -ForceUpgrade

### END