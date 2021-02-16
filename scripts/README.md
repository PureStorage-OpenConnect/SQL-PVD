### Pure Validated Design

# Scripts Folder
#### Installation and configuration of FlashArray and SQL FCI on-premises:
* **Create-ESXi-VMs-RDM.ps1**
  * Create a Windows Server Failover Cluster VMs with RDM disk on vSphere ESXi.
* **Create-WSFC-Sqlfci-VMware.ps1**
  * Create a 4-node WSFC and SQLFCI with Vmware VMs.
* **Create-OffloadfromPod.ps1**
  * Create Offload Targets from Pod on FlashArray.
* **Create-SSMS-Backups.ps1**
  * Create and restore application consistent snapshots using Pure Storage SSMS extsnsion, VSS provider, and SQLbackup SDK.

#### Installation and configuration of Pure Cloud Block Store and SQL FCI on Azure:
* **Create-sqlfci-Azure.ps1**
  * Create a 2-node Windows Server Failover Cluster and SQL Server Failover Instance in Azure on Azure Virtual Machines. The script requires the _CreateWSFCSharedDisk.json_ file.
* **CreateWSFCSharedDisk.json**
  * This file is used with the _create-sqlfci-Azure.ps1_ file to create an initial shared disk in Azure.
* **Create-Azure-offload-target.ps1**
  * Create an Azure Blob Offload Target on a Pure FlashArray. This includes the creation of the Azure Storage Account and configuration of the FlashArray.
* **Create-ArrayReplicationwithCBS.ps1**

<!-- wp:separator -->
<hr class="wp-block-separator"/>
<!-- /wp:separator -->

We encourage the use of PRs. Please issue a Pull Request (PR) if you wish to request merging your branches in this repository.

_The contents of the repository are intended as examples and should be modified to work in your individual environments. No scripts should be used in a production environment without fully testing them in a development or lab environment first. There are no expressed or implied warranties or liavbility for the use of these example scripts and templates._


