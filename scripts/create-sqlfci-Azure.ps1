
## Create WSFC
# Define variables
$resourceGroup = wsfc-rg
$location = 'uswest2'
$vmNode1Name = "cluster-node1"
$vmNode2Name = "cluster-node2"
$clusterName = "cluster1"
$clusterIPAddess = "10.10.1.1"
$sharedDiskName = "shareddisk1"
$ppgName = "group1-ppg" # Only if you use proximity placement groups

# Create the shared disk
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroup -TemplateFile "CreateWSFCSharedDisk.json"
$vm = Get-AzVM -ResourceGroupName $resourceGroup -Name $vmNode1Name
$dataDisk = Get-AzDisk -ResourceGroupName $resourceGroup -DiskName $sharedDiskName
$vm = Add-AzVMDataDisk -VM $vm -Name $sharedDiskName -CreateOption Attach -ManagedDiskId $dataDisk.Id -Lun <available LUN - check disk setting of the VM>
Update-AzVM -VM $vm -ResourceGroupName $resourceGroup

# Create the cluster for Server 2019. Comment out for Server 2012R2 or 2016 and uncomment the line further below
New-Cluster -Name $clusterName -Node ("<node1>", "<node2>") –StaticAddress $clusterIPAddress -NoStorage -ManagementPointNetworkType Singleton
# Create the cluster for Server 2012R2 or 2016. Comment out for Server 2019 and uncomment the line above.
# New-Cluster -Name <FailoverCluster-Name> -Node ("<node1>", "<node2>") –StaticAddress <n.n.n.n> -NoStorage

# Create witness

# Validate cluster


New-Cluster -Name "cluster1" -Node ("node1", "node2", "node3", "node4")  -NoStorage –StaticAddress x.x.x.x

## Create SQLFCI
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

