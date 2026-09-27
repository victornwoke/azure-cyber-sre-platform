# Deployment guide

This guide deploys the Terraform configuration in this repository. It assumes the operator has Azure permissions to create the declared resources and assign the Data Factory managed identity the `Storage Blob Data Contributor` role.

## What Terraform deploys

| Area | Resources |
| --- | --- |
| Foundation | One resource group and virtual network. |
| Network | `snet-platform`, `snet-data`, and an NSG associated with `snet-platform`. No NSG rules are declared. |
| Data | One StorageV2 account with ADLS Gen2 enabled and `raw` / `processed` filesystems. |
| Integration | One system-assigned Azure Data Factory and its storage data-plane role assignment. |
| Observability | One Log Analytics workspace with 30-day retention. |
| Secrets | One RBAC-enabled standard Key Vault. No vault role assignments or secrets are created. |

## Before you begin

1. Select a location and non-overlapping VNet/subnet CIDRs.
2. Choose a lowercase, globally unique `unique_suffix`; it participates in the globally unique storage account and Key Vault names.
3. Bootstrap an Azure Storage account/container for remote Terraform state, ideally in a separately managed subscription or resource group.
4. Confirm the deployer can create resources and role assignments. The latter normally requires `Owner` or `User Access Administrator` at the target scope.
5. Authenticate using `az login`, managed identity, workload identity federation, or the CI/CD platform’s configured service connection.

## Configure variables

Keep environment values outside version control. For example, create `env/dev.tfvars` (and ensure your local ignore rules exclude it):

```hcl
subscription_id         = "<subscription-id>"
location                = "uksouth"
environment             = "dev"
unique_suffix           = "<unique-suffix>"
project_name            = "cyber-sre-platform"
address_prefixes        = ["10.20.0.0/16"]
subnet_address_prefixes = ["10.20.1.0/24", "10.20.2.0/24"]
```

`subnet_address_prefixes` must contain at least two CIDRs: index `0` becomes the platform subnet and index `1` becomes the data subnet. Terraform does not currently validate their length or CIDR overlap, so review these values carefully.

## Initialise state

Terraform declares an `azurerm` backend but intentionally does not embed environment-specific backend values. Initialise with values for the state storage location:

```bash
cd terraform
terraform init \
  -backend-config="resource_group_name=<state-resource-group>" \
  -backend-config="storage_account_name=<state-storage-account>" \
  -backend-config="container_name=<state-container>" \
  -backend-config="key=cyber-sre.dev.tfstate"
```

Do not place backend access keys in shell history or commit a `backend.hcl` file. Prefer Microsoft Entra ID authentication and scoped access to the state container.

## Plan and apply

```bash
terraform fmt -check -recursive
terraform validate
terraform plan -var-file="../env/dev.tfvars" -out=tfplan
terraform show tfplan
terraform apply tfplan
```

Keep the binary plan private and apply the exact reviewed plan. A plan can contain identifiers and resource metadata, so do not commit it or publish it broadly.

## Validate the deployment

```bash
az resource list --resource-group rg-cyber-sre-dev --output table
pwsh ./powershell/Test-PlatformHealth.ps1 -ResourceGroupName rg-cyber-sre-dev
```

Then verify in Azure that Data Factory’s system-assigned identity has `Storage Blob Data Contributor` at the storage-account scope and that both `raw` and `processed` filesystems exist. The health check verifies only control-plane resource discovery; use a real pipeline or authenticated data-plane test for end-to-end validation.

## CI/CD implementation notes

The repository includes both [GitHub Actions](../.github/workflows/ci.yml) and [Azure DevOps](../azure-pipelines.yml) definitions. They are templates, not ready-to-run production workflows:

- Both need Azure authentication configured for Terraform.
- Both need the same remote backend configuration during every `terraform init`.
- The GitHub workflow must pass the environment’s variable file or secure pipeline variables to `terraform plan`.
- The Azure DevOps `Plan` and `Apply` stages run in separate jobs; each needs `terraform init` before plan/apply and the reviewed plan must be preserved between them.
- Pin Terraform and action/task versions rather than using `latest`; configure the provider constraint in Terraform as well.
- Use a protected production environment with required approvals and least-privilege federated identity.

Choose one CI/CD system to perform applies for a given state key. Concurrent or competing apply paths can lead to state locking and operational confusion.

## Destroying an environment

Only destroy a confirmed non-production environment after checking dependencies and retained data. From `terraform/`:

```bash
terraform plan -destroy -var-file="../env/dev.tfvars" -out=destroy.tfplan
terraform show destroy.tfplan
terraform apply destroy.tfplan
```

Azure Key Vault soft delete is configured for seven days, so vault recovery may remain possible after destruction. Other data-retention behavior depends on Azure service settings and must be assessed before executing a destroy.
