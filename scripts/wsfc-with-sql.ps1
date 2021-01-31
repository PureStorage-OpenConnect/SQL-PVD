### WSFC start

# define variables
$clusterName = 'cluster1'
$clusterDomain = 'domain.com'
$domainAdmin = Get-Credential

# pre-stage the AD stuff
New-ClusterNameAccount -Name $clusterName -Domain $clusterDomain - Credentials $domainAdmin


# install the roles on the nodes
Install-WindowsFeature -Name Failover-Clustering –IncludeManagementTools –ComputerName node1
Install-WindowsFeature -Name Failover-Clustering –IncludeManagementTools –ComputerName node2
Install-WindowsFeature -Name Failover-Clustering –IncludeManagementTools –ComputerName node3
Install-WindowsFeature -Name Failover-Clustering –IncludeManagementTools –ComputerName node4

# run cluster validation on all nodes
$nodes = "node1", "node2", "node3", "node4"
try {
foreach ($node in $nodes) {
Test-Cluster –Node $node
}
}
catch {
    throw
}

# create the cluster. remove -nostaorge param to allow auto add of available shared volumes
New-Cluster -Name "cluster1" -Node ("node1", "node2", "node3", "node4")  -NoStorage –StaticAddress x.x.x.x

# Need to check DNS for cluster name object

# need to define and add volumes to hosts

# need to create local volumes, format disks, and assign drive letters

# set file share witness?
Set-ClusterQuorum -NodeAndFileShareMajority \\CentralFileServer\FileShareWitness\cluster1

### WSFC end

### SQL Start
# ISO path, mount, extract, & dismount
$ImagePath = 'C:\en_sql_server_2019_developer_x64_dvd.iso'
New-Item -Path C:\SQLServer -ItemType Directory
Copy-Item -Path (Join-Path -Path (Get-PSDrive -Name ((Mount-DiskImage -ImagePath $ImagePath -PassThru) | Get-Volume).DriveLetter).Root -ChildPath '*') -Destination C:\SQLServer\ -Recurse
Dismount-DiskImage -ImagePath $ImagePath

# set install variables
$SqlCredential = Get-Credential # This should be the domain admins creds
$dataDir = 'd:\data'
$clusterNetName = 'cluster1'
$clusterIpAddress = 'x.x.x.x'

# check for nuget
$providers = (Get-PackageProvider).Name
if ($providers -cnotcontains "NuGet") {
    Get-PackageProvider -Name NuGet -ForceBootstrap
}

# get the sqlserverdsc module
Install-Module -Name SqlServerDsc

# check for SQL Module. If not present, install it.
    if ((Get-InstalledModule -Name "SqlServer" -ErrorAction SilentlyContinue) -eq $null) {
        Install-Module -Name SqlServer
        Import-Module SqlServer
    }

# DSC config for initial cluster creation
Configuration SQLClusterNode1
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName SqlServerDsc
    node localhost
    {
        WindowsFeature 'NetFramework45' {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }

        SqlSetup 'InstallDefaultInstance'
        {
            InstanceName                = 'MSSQLSERVER'
            Features                    = 'SQLENGINE, CONN, FULLTEXT'
            Action                      = 'InstallFailoverCluster'
            FailoverClusterNetworkName  = $clusterNetName
            FailoverClusterIPAddress    = $clusterIpAddress
            InstallSQLDataDir           = $dataDir
            SourcePath                  = 'C:\SQLServer'
            SQLSysAdminAccounts         = @('Administrators')
            DependsOn                   = '[WindowsFeature]NetFramework45'
            NpEnabled                   = $true
            TcpEnabled                  = $true
            UseEnglish                  = $true
            PsDscRunAsCredential        = $SqlCredential
            ForceReboot                 = $false
            UpdateEnabled               = 'False'
            InstallSharedDir            = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir         = 'C:\Program Files (x86)\Microsoft SQL Server'
            InstanceDir                 = 'C:\Program Files\Microsoft SQL Server'
        }
    }
}
SQLClusterNode1

# DSC config for initial cluster creation
Configuration SQLClusterNode2
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName SqlServerDsc
    node localhost
    {
        WindowsFeature 'NetFramework45' {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }

        SqlSetup 'InstallDefaultInstance' {
            InstanceName               = 'MSSQLSERVER'
            Features                   = 'SQLENGINE, CONN, FULLTEXT'
            Action                     = 'InstallFailoverCluster'
            FailoverClusterNetworkName = $clusterNetName
            FailoverClusterIPAddress   = $clusterIpAddress
            InstallSQLDataDir          = $dataDir
            SourcePath                 = 'C:\SQLServer'
            SQLSysAdminAccounts        = @('Administrators')
            DependsOn                  = '[WindowsFeature]NetFramework45'
            NpEnabled                  = $true
            TcpEnabled                 = $true
            UseEnglish                 = $true
            PsDscRunAsCredential       = $SqlCredential
        }
    }
}
SQLClusterNode2

# start install on first node and establish SQL cluster - node1
Start-DscConfiguration -Path C:\SQLClusterNode1 -Wait -Force -Verbose




# continue with node2, node3, node 4





# validate sql and cluster roles
# If Test succeeds, remove the folders
if (Test-DscConfiguration) {
    Remove-Item .\SqlServerConfig -Recurse
    Remove-Item $SourcePath -Recurse
}

# validate SQL services running on all nodes
Get-Service -Name *SQL*




# restore test dbs





#
