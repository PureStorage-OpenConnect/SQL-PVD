# Q's work

#w/o vCenter certificate setup you have to ignore
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

#connect to vCenter creds popup or automate pulling encrypted creds with other switches
$vcenter = Connect-VIServer -Server 10.21.201.188

#rather than specify 5000 things, I created a VM prepped it, made it into a template so we'll start by assigning a template to a variable
$VMTemplate = Get-Template -Name W2019Template

#specify which datastore to place the VM boot VMDK into
$myDatastore = Get-Datastore -Name VM

#specify a specific esxi host, or you could specify a cluster with DRS
$vmhost = Get-VMHost -Name 10.21.201.54

#create the VM
New-VM -Name SQLVM1 -Template $VMTemplate -Datastore $myDatastore -ResourcePool $vmhost -server $vcenter

#Attach RDM to VM1
$hd1 = New-HardDisk -VM SQLVM1 -DiskType RawPhysical -DeviceName /vmfs/devices/disks/naa.624a9370b6d4bc4f2d8a416d00011017 -Datastore “VM”

#move RDM disks to new pvscsi controller with physical bus sharing
Get-HardDisk -VM sqlvm1 -DiskType RawPhysical | New-ScsiController -type paravirtual -bussharingmode physical

#attach RDM to VMx
$hd2 = New-HardDisk -VM sqlvm2 -DiskPath $hd1.FileName
$ctrl2 = New-ScsiController -HardDisk $hd2 -Type paravirtual -BusSharingMode Physical