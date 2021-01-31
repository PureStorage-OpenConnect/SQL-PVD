### Pure Validated Design

# Template Folder
## Files in this repository:
* _cbs_parameterfile.json_ and _cbs_templatefile.json_
  - These files are used together as an ARM Template deployment of the Pure Cloud Block Store on Azure. The _cbs_parameterfile.json_ file must be modified to suit your environment. To deploy this template, run these commands in Azure CLI:
    - `az account set --subscription <your_subscription_ID>`
    - `az deployment group create --resource-group <resource_group> --template-file cbs_templatefile.json --parameters cbs_parameterfile.json`

<!-- wp:separator -->
<hr class="wp-block-separator"/>
<!-- /wp:separator -->

We encourage the use of PRs. Please issue a Pull Request (PR) if you wish to request merging your branches in this repository.

_The contents of the repository are intended as examples and should be modified to work in your individual environments. No scripts should be used in a production environment without fully testing them in a development or lab environment first. There are no expressed or implied warranties or liavbility for the use of these example scripts and templates._


