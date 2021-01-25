
# create PPG


# create WSFC

New-Cluster -Name "cluster1" -Node ("node1", "node2", "node3", "node4")  -NoStorage –StaticAddress x.x.x.x

# create a shared disk on CBS for FCI use
# Do we need PPGs?

$resourceGroup = "sqlfci-rg"
$location = "uswest2"
$ppgName = "sqlfci-ppg"
$vm = Get-AzVM -ResourceGroupName "sqlfci-rg" `
    -Name "node1"
$dataDisk = Get-AzDisk -ResourceGroupName $resourceGroup `
    -DiskName "sql_share_1"
$vm = Add-AzVMDataDisk -VM $vm -Name "sql_share_1" `
    -CreateOption Attach -ManagedDiskId $dataDisk.Id `
    -Lun <available LUN - check disk setting of the VM>
Update-AzVM -VM $vm -ResourceGroupName $resourceGroup

# install agent to manage via AZ Portal
# Get the existing compute VM
$vm = Get-AzVM -Name "node1" -ResourceGroupName $resourceGroup

# Register SQL VM with 'Lightweight' SQL IaaS agent
New-AzSqlVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Location $vm.Location -LicenseType PAYG -SqlManagementType LightWeight

