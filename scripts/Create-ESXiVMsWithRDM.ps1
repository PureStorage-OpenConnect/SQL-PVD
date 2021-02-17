<#
Create-ESXiVMsWithRDM.ps1

: Revision 1.0.0.0
:: initial release

Example script to create ESXi virtual machines with RDM disk storage.
This is not intended to be a complete run script. It is for example purposes only.
Variables should be modified to suit the environment.

This script is AS-IS. No warranties expressed or implied by Pure Storage or the creator.

Requirements:
  vSphere PowerCLI
  Pure Storage PowerShell SDK v1 module
  Flasharray array admin login credentials
  Sysprepped VM Template
#>

#### Start
## Define variables
$VCenterServerIP = "10.21.201.188"
# Without vCenter certificate setup, you have to ignore cert errors. If certificates are configured, comment out the line.
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
# Connect to vCenter creds popup or automate pulling encrypted creds with other switches.
$vcenter = Connect-VIServer -Server $VCenterServerIP
# Rather than specify all the configuration options, create a VM, sysprep it, and make it into a template.
# Start by assigning a template to a variable.
$VMTemplate = Get-Template -Name "W2019Template"
# Specify which datastore to place the VM boot VMDK into.
$myDatastore = Get-Datastore -Name "VM"
# Specify a specific ESXi host to place a new VM, or you could specify a cluster with DRS.
$vmhost = Get-VMHost -Name "10.21.201.54"
$VMName1 = "testvm1"
$VMName2 = "testvm2"
## End Define variables

## Begin Steps for VMName1, the first VM in the Microsoft Failover Cluster.
# Step 1: create a VM.
New-VM -Name testvm1 -Template $VMTemplate -Datastore $myDatastore -ResourcePool $vmhost -server $vcenter

# Step 2: Attach RDM to VMName1.
$hd1 = New-HardDisk -VM $VMName -DiskType RawPhysical -DeviceName /vmfs/devices/disks/naa.624a9370b6d4bc4f2d8a416d00011017 -Datastore $myDatastore

# If you do not know the ConsoleDeviceName, enumerate the devices on the ESXi host to see LUN#, Size, ConsoleDeviceName:
#Get-ScsiLun -VMhost $vmhost | Format-List

# Step 3: On VMName1, move RDM disks to new pvscsi controller with physical bus sharing so more than 1 VM can connect to the RDM.
Get-HardDisk -VM $VMName1 -DiskType RawPhysical | New-ScsiController -type paravirtual -bussharingmode physical

## End Steps for VMName1

## Begin Steps for each additional VM in the Microsoft Server Failover Cluster.
# Step 4: attach RDM to each additional VMs.
$hd2 = New-HardDisk -VM $VMName2 -DiskPath $hd1.FileName
$ctrl2 = New-ScsiController -HardDisk $hd2 -Type paravirtual -BusSharingMode Physical
## End Steps for VMName2, repeat for each additional VM in the Microsoft Server Failover Cluster.

## END