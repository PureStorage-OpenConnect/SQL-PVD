# Create-sqlfci-Azure.ps1
#
# : Revision 1.0.0.0
# :: initial release
#
# Example script to create a 2-node SQL Server Failover Cluster Instance on Azure VMs.
# This is not intended to be a complete run script. It is for example purposes only.
# Variables should be modified to suit the environment.
#
# This script is AS-IS. No warranties expressed or implied by Pure Storage or the author.
#
# Requirements:
#  Azure Az module
#  Pure Storage PowerShell SDK v1 module
#  Flasharray array admin login credentials
#
#
#### Start
## Define variables
$resourceGroup = 'wsfc-rg'
$location = 'westus2'
$vmNode1Name = "node1"
$vmNode2Name = "node2"
$clusterName = "cluster1"
$clusterIPAddress = "10.10.1.1"
$sharedDiskName = "shareddisk1"
$ppgName = "sqlfci-ppg" # Only necessary if you use proximity placement groups
$arrayEndpoint = "10.1.1.1" # On-premises FlashArray or Pure Cloud Block Store IP address
$domainName = "mylab.local" # change the existing AD domain name
$domainDCIp = "10.1.1.255" # domain controller IP for domain join

## Verify requirements
try {
    Write-Host "Checking for elevated permissions..."
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again."
        Break
    }
    else {
        Write-Host "Script is running as administrator. Continuing..." -ForegroundColor Green
    }

    # Check for modules
    Write-Host "Checking, installing, and importing prerequisite modules..."
    Write-Host "If the Az module has not been previously installed, this will take some time."
    Write-Host "If prompted to enable Nuget, please accept."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $modulesArray = @(
        "Az",
        "PureStoragePowerShellSDK"
    )
    ForEach ($mod in $modulesArray) {
        If (Get-Module -ListAvailable $mod) {
            Continue
        }
        Else {
            Install-Module $mod -Force -AllowClober -ErrorAction 'SilentlyContinue'
            Import-Module $mod -ErrorAction 'SilentlyContinue'
        }
    }
}
    catch {
        Write-Host "There was an problem verifying the requirements. Please try again or submit an Issue in the GitHub Repository."
    }
#
### Begin Azure Work

########################### DOMAIN CONTROLLER??????

# Connect to Azure
Connect-AzAccount

# Please uncomment and edit if you require switching subscription context which would be necessary if you have access to multiple subscriptions.
# Get-AzContext
# Set-AzContext -Subscription <subscrptionID_or_name>

## Create the VMs in an Availability Zone.
# You must verify that the region you wish to place the VMs has an Availability Zone. In this example, we will use West US 2 region which has Zones 1,2,3.
# To determine which Zones are available for a region, run this cmdlet, replacing the region:
# Get-AzComputeResourceSku | where {$_.Locations.Contains("eastus")};
New-AzResourceGroup -Name $resourceGroup -Location westus2
# Create a subnet configuration
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name fciSubnet -AddressPrefix 172.1.1.0/24

## Create a virtual network
# You may choose to an existing vNet.
# Be sure to alter the parameters as necessary.
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location westus2 -Name fciVNet -AddressPrefix 172.1.0.0/16 -Subnet $subnetConfig

## Create a public IP address in an availability zone and specify a DNS name
$pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -Location westus2 -Zone 1 -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name "fcipublicdns$(Get-Random)" -Sku Standard

## Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleRDP  -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow

## Create a network security group
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location westus2 -Name fcinsg -SecurityRules $nsgRuleRDP

## Create a virtual network card and associate with public IP address and NSG
$nic = New-AzNetworkInterface -Name myNic -ResourceGroupName $resourceGroup -Location westus2 -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

## Define a credential object
$cred = Get-Credential

## Create VMs
# Alter the size of the VMs to fit workload.
$vmConfig1 = New-AzVMConfig -VMName $vmNode1Name -VMSize Standard_DS2_v3 -Zone 1 -EnableUltraSSD | Set-AzVMOperatingSystem -Windows -ComputerName $vmNode1Name -Credential $cred | Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2019-Datacenter -Version latest | Add-AzVMNetworkInterface -Id $nic.Id
New-AzVM -ResourceGroupName $resourceGroup -Location westus2 -VM $vmConfig1

$vmConfig2 = New-AzVMConfig -VMName $vmNode2Name -VMSize Standard_DS2_v3 -Zone 1 -EnableUltraSSD | Set-AzVMOperatingSystem -Windows -ComputerName $vmNode2Name -Credential $cred | Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2019-Datacenter -Version latest | Add-AzVMNetworkInterface -Id $nic.Id
New-AzVM -ResourceGroupName $resourceGroup -Location westus2 -VM $vmConfig2 -EnableUltraSSD

## Add VMs to domain
# Azure defaults to a single NIC, so one index DNS change
$netIndex = Get-NetAdapter -CimSession $vmNode1name | Select-Object InterfaceIndex
Set-DnsClientServerAddress -CimSession $vmNode1name -InterfaceIndex $netIndex -ServerAddresses ($domainDCIp,"1.1.1.1")
$netIndex = Get-NetAdapter -CimSession $vmNode2name | Select-Object InterfaceIndex
Set-DnsClientServerAddress -CimSession $vmNode2name -InterfaceIndex $netIndex -ServerAddresses ($domainDCIp, "1.1.1.1")
Add-Computer -ComputerName vmNode1name, vmNode2name -DomainName $domainName –Credential $cred -Restart –Force

### End Azure Work

### Begin pre-WSFC work

## Add WSFC and MPIO features to VMs. This action requires a restart of the VM.
$servers = ($vmNode1Name, $vmNode2Name)
foreach ($server in $servers) {
    Get-Service -Name MSiSCSI | Start-Service
    Start-Sleep -Seconds 2
    Set-Service -Name MSiSCSI -StartupType Automatic
    Install-WindowsFeature -Name Failover-Clustering,Multipath-IO -ComputerName $server -Credential $cred -IncludeManagementTools -Restart
}
## Configure MPIO & iSCSI. This MPIO SupportedHW change and MPIOSetting changes require a reboot.
foreach ($server in $servers) {
    New-MSDSMSupportedHw -VendorId PURE -ProductId FlashArray
    Enable-MSDSMAutomaticClaim -BusType iSCSI
    Set-MSDSMGlobalDefaultLoadBalancePolicy -Policy LQD
    Set-MPIOSetting -NewPathRecoveryInterval 20 -CustomPathRecovery Enabled -NewPDORemovePeriod 30 -NewDiskTimeout 60 -NewPathVerificationState Enabled
    Restart-Computer -ComputerName $server -Credential $cred
}

### End pre-WSFC work

### Begin iSCSI and Array work

## Get the iSCSI node address from the VMs
$iqn1 = (Get-InitiatorPort -CimSession $vmNode1Name | Where-Object { $_.NodeAddress -like "*iqn*" }).NodeAddress
$iqn2 = (Get-InitiatorPort -CimSession $vmNode2Name | Where-Object { $_.NodeAddress -like "*iqn*" }).NodeAddress

## Connect to Array
# We need to connect to the array at this point to connect the hosts and get iSCSI info from the array. While were here, create the Host Group.
# There are several ways to connect to a FlashArray. please refer to the Powershell SDK documentation at https://support.purestorage.com.
# The method below will prompt for the user name and password for the array.
$array = New-PfaArray -EndPoint $arrayEndpoint -Credentials (Get-Credential) -IgnoreCertificateError
# This method will use pre-defined variables (not stated in this example script) for the credentials.
# Connect-Pfa2Array -Endpoint $array -Username $Username -Password $Password -IgnoreCertificateError

## Create the hosts and host group
New-PfaHost –Array $array –Name $vmNode1Name –IqnList $iqn1
New-PfaHost –Array $array –Name $vmNode2Name –IqnList $iqn2
New-PfaHostGroup -Array $array -Hosts $vmNode1Name, $vmNode2Name -Name "sqlfcigroup"
## Create volume and add to hostgroup
New-PfaVolume –Array $array –VolumeName "sqlfci-vol1" –Unit "TB" –Size 1
New-PfaHostGroupVolumeConnection -Array $array -VolumeName "sqlfci-vol1" -HostGroupName "sqlfcigroup"
## Retrieve array iSCSI address. Only one address is required for CBS arrays.
$ips = (Get-PfaArrayPorts -Array $array).portal
    Foreach ($ip in $ips) {
        $ipNoPort = ($ip | Select-String -Pattern "\d{1,3}(\.\d{1,3}){3}" -AllMatches).Matches.Value
    }
$servers = ($vmNode1Name, $vmNode2Name)
    foreach ($server in $servers) {
    New-IscsiTargetPortal -TargetPortalAddress $ipNoPort
}

$HostIPs = Get-WmiObject Win32_NetworkAdapterConfiguration -Namespace 'root\CIMv2' | Where-Object { $_.IPEnabled }
    foreach ($HostIP in $HostIPs) {
    New-Object PSObject -Property @{
    IPAddress = $HostIP.IPAddress[0]
    Subnet = $HostIP.IPSubnet[0]
    Adapter = $HostIP.Description
        }
    }

$IscsiInitTargetClass = Get-WmiObject -Namespace 'root\wmi' -Class MSiSCSIInitiator_TargetClass
    foreach ($IscsiInitTarget in $IscsiInitTargetClass) {
        foreach ($IscsiTargetPortal in $IscsiInitTarget.PortalGroups.Get(0).Portals) {
            New-Object PSObject -Property  @{
            IscsiTarget = $IscsiInitTarget.TargetName
            IscsiTargetAddress = $IscsiTargetPortal.Address
            IscsiTargetPort = $IscsiTargetPortal.Port
            }
        }
    }

New-IscsiTargetPortal -InitiatorPortalAddress $iqn1 -TargetPortalAddress $array1nic -InitiatorInstanceName "ROOT\ISCSIPRT\0000_0"
New-IscsiTargetPortal -InitiatorPortalAddress $iqn2 -TargetPortalAddress $array1nic -InitiatorInstanceName "ROOT\ISCSIPRT\0000_0"

### End iSCSI and Array work


### Begin Initial Cluster Work
## Create WSFC
# These commands must be run on one of the cluster nodes unless modified for remoting.
# Run pre-cluster validation on hardware and software
# Be sure to correct any issues with storage or network-related issues before proceeding.
Test-Cluster -Node $vmNode1Name, $vmNode2Name

## Create the cluster for Server 2019. Comment out for Server 2012R2 or 2016 and un-comment the line further below
New-Cluster -Name $clusterName -Node ($vmNode1Name, $vmNode2Name) –StaticAddress $clusterIPAddress -NoStorage -ManagementPointNetworkType Singleton
## Create the cluster for Server 2012R2 or 2016. Comment out for Server 2019 and un-comment the line above.
# New-Cluster -Name <FailoverCluster-Name> -Node ("<node1>", "<node2>") –StaticAddress <n.n.n.n> -NoStorage

## Validate cluster after cluster creation
Test-Cluster -Node $vmNode1Name, $vmNode2Name

### End Initial Cluster Work

### Begin Final Cluster Work
## Configure volume for use in cluster


## Add volume to Cluster as CSV



## Create SQLFCI




### End Final Cluster Work


## Install the SQLIaaSAgent to manage the SQL server via the Azure Portal.
# This is optional.
$vm = Get-AzVM -Name $vmNode1Name -ResourceGroupName $resourceGroup
New-AzSqlVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Location $vm.Location -LicenseType PAYG -SqlManagementType LightWeight
$vm = Get-AzVM -Name $vmNode2Name -ResourceGroupName $resourceGroup
New-AzSqlVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Location $vm.Location -LicenseType PAYG -SqlManagementType LightWeight






## Create a new shared disk.
# This is optional. This can be a temporary disk for the cluster quorum until the FlashArray Volumes are connected.
# The "NewWSFCSharedDisk.json" file must exist in the same folder for this function to work.
function New-Shared-Disk () {
    New-AzResourceGroupDeployment -ResourceGroupName $resourceGroup -TemplateFile "NewWSFCSharedDisk.json"
    $vm = Get-AzVM -ResourceGroupName $resourceGroup -Name $vmNode1Name
    $dataDisk = Get-AzDisk -ResourceGroupName $resourceGroup -DiskName $sharedDiskName
    $vm = Add-AzVMDataDisk -VM $vm -Name $sharedDiskName -CreateOption Attach -ManagedDiskId $dataDisk.Id -Lun 2
    Update-AzVM -VM $vm -ResourceGroupName $resourceGroup
}





$vm = Get-AzVM -ResourceGroupName "sqlfci-rg" -Name "node1"
$dataDisk = Get-AzDisk -ResourceGroupName $resourceGroup -DiskName "sql_share_1"
$vm = Add-AzVMDataDisk -VM $vm -Name "sqlshare_1" -CreateOption Attach -ManagedDiskId $dataDisk.Id -Lun 2
Update-AzVM -VM $vm -ResourceGroupName $resourceGroup