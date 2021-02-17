### Pure Validated Design

# PVD Template Folder
## Files in this repository:
- [**cbs_parameterfile.json**](https://github.com/PureStorage-OpenConnect/SQL-PVD/blob/main/templates/cbs_parameterfile.json) and [**cbs_templatefile.json**](https://github.com/PureStorage-OpenConnect/SQL-PVD/blob/main/templates/cbs_templatefile.json)
  - These files are used together as an ARM Template deployment of the Pure Cloud Block Store on Azure. The _cbs_parameterfile.json_ file must be modified to suit your environment. To deploy this template, run these commands in Azure CLI:
    - `az account set --subscription <your_subscription_ID>`
    - `az deployment group create --resource-group <resource_group> --template-file cbs_templatefile.json --parameters cbs_parameterfile.json`
- [**Deploy_PureCloudBlockStore_ARM.ps1**]()
  - Contains the Azure CLI commands mentioned above.

<!-- wp:separator -->
<hr class="wp-block-separator"/>
<!-- /wp:separator -->

We encourage the modification and expansion of these templates by the community. Although not necessary, please issue a Pull Request (PR) if you wish to request merging your modified code in to this repository.

<!-- wp:separator -->
<hr class="wp-block-separator"/>
<!-- /wp:separator -->

_The contents of the repository are intended as examples only and should be modified to work in your individual environments. No template examples should be used in a production environment without fully testing them in a development or lab environment first. There are no expressed or implied warranties or liavbility for the use of these example scripts and templates by Pure Storage or their creators._
