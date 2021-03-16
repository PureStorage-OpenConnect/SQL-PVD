### Pure Validated Design

**Link to the PVD - [Increase SQL Server Resilience with Hybrid Cloud](https://www.purestorage.com/docs.html?item=/type/pdf/subtype/doc/path/content/dam/pdf/en/validated-design-guides/vd-increase-sql-server-resilience.pdf)**

# Script Examples Folder
#### Deployment Guide:
* [**New-ESXiVMswithRDM.ps1**](https://github.com/PureStorage-Connect/SQL-PVD/blob/main/scripts/New-ESXiVMsWithRDM.ps1)
  * Create a Windows Server Failover Cluster VMs with RDM disk on vSphere ESXi.
* [**New-FAActiveCluster.ps1**](https://github.com/PureStorage-Connect/SQL-PVD/blob/main/scripts/New-FAActiveCluster.ps1)
  * Create an ActiveCluster between two FlashArrays.
* [**Set-FAwithESXi.ps1**](https://github.com/PureStorage-Connect/SQL-PVD/blob/main/scripts/Update-FAwithESXi.ps1)
  * Set the configuration of the ESXi hosts in the FlashArray.
* [**New-OffloadTargetSnapshot.ps1**](https://github.com/PureStorage-Connect/SQL-PVD/blob/main/scripts/New-OffloadTarget.ps1)
  * Create an Offload Target and update a snapshot Offload Target from a FlashArray pod.
* [**New-SSMSBackupsandRestores.ps1**](https://github.com/PureStorage-Connect/SQL-PVD/blob/main/scripts/New-SSMSBackupsAndRestores.ps1)
  * Create and restore application consistent snapshots backups using the Pure Storage SSMS extsnsion, VSS provider, and SQLBackup SDK.
* [**New-PureAzureEnvironment.ps1**](https://github.com/PureStorage-Connect/SQL-PVD/blob/main/scripts/New-PureAzureEnvironment.ps1)
  * Create an Azure environment that could host a 2-node Windows Server Failover Cluster and SQL Server Failover Instance on Azure Virtual Machines. The script requires the _CreateWSFCSharedDisk.json_ file.
* [**CreateWSFCSharedDisk.json**](https://github.com/PureStorage-Connect/SQL-PVD/blob/main/scripts/NewWSFCSharedDisk.json)
  * This file is used with the _New-PureAzureEnvironment.ps1_ file to create an initial shared disk in Azure.
* [**New-AzureOffloadTarget.ps1**](https://github.com/PureStorage-Connect/SQL-PVD/blob/main/scripts/New-AzureOffloadTarget.ps1)
  * Create an Azure Blob Offload Target on a Pure FlashArray. This includes the creation of the Azure Storage Account and configuration of the FlashArray.
* [**New-FlashArrayReplication.ps1**](https://github.com/PureStorage-Connect/SQL-PVD/blob/main/scripts/New-FlashArrayReplication.ps1)
  * Create replication between two FlashArrays, either on-premises or with Pure Cloud Block Store.


## Pure Cloud Block Store deployment files
- [**cbs_parameterfile.json**](https://github.com/PureStorage-OpenConnect/SQL-PVD/blob/main/scripts/cbs_parameterfile.json) and [**cbs_templatefile.json**](https://github.com/PureStorage-OpenConnect/SQL-PVD/blob/main/scripts/cbs_templatefile.json)
  - These files are used together as an ARM Template deployment of the Pure Cloud Block Store on Azure. The _cbs_parameterfile.json_ file must be modified to suit your environment.
- [**New-AzureCloudBlockStoreARM.ps1**](https://github.com/PureStorage-OpenConnect/SQL-PVD/blob/main/scripts/New-AzureCloudBlockStoreARM.ps1)
  - Contains the PowerShell and Azure CLI commands to deploy the provided templates.

<!-- wp:separator -->
<hr class="wp-block-separator"/>
<!-- /wp:separator -->

We encourage the modification and expansion of these scripts by the community. Although not necessary, please issue a Pull Request (PR) if you wish to request merging your modified code in to this repository.

<!-- wp:separator -->
<hr class="wp-block-separator"/>
<!-- /wp:separator -->

_The contents of the repository are intended as examples only and should be modified to work in your individual environments. No script examples should be used in a production environment without fully testing them in a development or lab environment first. There are no expressed or implied warranties, official support, or liability for the use of these example scripts and templates as presented by Pure Storage and/or their creators._
