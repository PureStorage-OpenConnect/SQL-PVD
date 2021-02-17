### Pure Validated Design

**Link to the PVD - [SQL Server Business Resilience with Hybrid Cloud](https://www.purestorage.com/)**

# Example Scripts Folder
#### Deployment Guide:
* [**Create-ESXiVMsWithRDM.ps1**](https://github.com/PureStorage-Connect/SQL-PVD/blob/main/scripts/Create-ESXiVMsWithRDM.ps1)
  * Create a Windows Server Failover Cluster VMs with RDM disk on vSphere ESXi.
* [**Create-ActiveCluster**](https://github.com/PureStorage-Connect/SQL-PVD/blob/main/scripts/Create-FAActiveCluster.ps1)
  * Create an ActiveCluster between two Flasharrays.
* [**Configure-FAwithESXi.ps1**](https://github.com/PureStorage-Connect/SQL-PVD/blob/main/scripts/Configure-FAwithESXi.ps1)
  * Configure the ESXi hosts in the FlashArray.
* [**Create-OffloadTargetFromPod.ps1**](https://github.com/PureStorage-Connect/SQL-PVD/blob/main/scripts/Create-OffloadTargetfromPod.ps1)
  * Create Offload Targets from a Pod on a FlashArray.
* [**Update-OffloadTarget.ps1**](https://github.com/PureStorage-Connect/SQL-PVD/blob/main/scripts/Update-OffloadTarget.ps1)
  * Workaround script to replicate data inside a pod to a snapshot offload target.
* [**Create-SSMSBackupsAndRestores.ps1**](https://github.com/PureStorage-Connect/SQL-PVD/blob/main/scripts/Create-SSMSBackupsAndRestores.ps1)
  * Create and restore application consistent snapshots using Pure Storage SSMS extsnsion, VSS provider, and SQLbackup SDK.
* [**Create-PureAzureEnvironment.ps1**](https://github.com/PureStorage-Connect/SQL-PVD/blob/main/scripts/Create-PureAzureEnvironment.ps1)
  * Create an Azure environment that could host a 2-node Windows Server Failover Cluster and SQL Server Failover Instance in Azure on Azure Virtual Machines. The script requires the _CreateWSFCSharedDisk.json_ file.
* [**CreateWSFCSharedDisk.json**](https://github.com/PureStorage-Connect/SQL-PVD/blob/main/scripts/NewWSFCSharedDisk.json)
  * This file is used with the _Create-PureAzureEnvironment.ps1_ file to create an initial shared disk in Azure.
* [**Create-AzureOffloadTarget.ps1**](https://github.com/PureStorage-Connect/SQL-PVD/blob/main/scripts/Create-AzureOffloadTarget.ps1)
  * Create an Azure Blob Offload Target on a Pure FlashArray. This includes the creation of the Azure Storage Account and configuration of the FlashArray.
* [**Create-FlashArrayReplication.ps1**](https://github.com/PureStorage-Connect/SQL-PVD/blob/main/scripts/Create-FlashArrayReplication.ps1)
  * Create replication between two FlashArrays, either on-premises or Cloud Block Store.


## Pure Cloud Block Store deployment files
- [**cbs_parameterfile.json**](https://github.com/PureStorage-OpenConnect/SQL-PVD/blob/main/scripts/cbs_parameterfile.json) and [**cbs_templatefile.json**](https://github.com/PureStorage-OpenConnect/SQL-PVD/blob/main/scripts/cbs_templatefile.json)
  - These files are used together as an ARM Template deployment of the Pure Cloud Block Store on Azure. The _cbs_parameterfile.json_ file must be modified to suit your environment.
- [**Deploy_PureCloudBlockStore_ARM.ps1**](https://github.com/PureStorage-OpenConnect/SQL-PVD/blob/main/scripts/cbs_parameterfile.json)
  - Contains the Azure CLI commands mentioned above.

<!-- wp:separator -->
<hr class="wp-block-separator"/>
<!-- /wp:separator -->

We encourage the modification and expansion of these scripts by the community. Although not necessary, please issue a Pull Request (PR) if you wish to request merging your modified code in to this repository.

<!-- wp:separator -->
<hr class="wp-block-separator"/>
<!-- /wp:separator -->

_The contents of the repository are intended as examples only and should be modified to work in your individual environments. No script examples should be used in a production environment without fully testing them in a development or lab environment first. There are no expressed or implied warranties or liavbility for the use of these example scripts and templates by Pure Storage or their creators._
