# Troubleshooting guide

Use this guide to diagnose common provisioning and operational failures. Preserve relevant Terraform output, Azure activity logs, Data Factory run IDs, and timestamps before making changes.

## Triage sequence

1. Identify the affected environment, Azure subscription, resource group, and time window.
2. Check Azure authentication and selected subscription.
3. Run the platform health check.
4. Review the Azure Activity Log and service-specific logs for the same time window.
5. Make the smallest safe correction, validate it, and capture the outcome in the incident record.

```powershell
Get-AzContext
./powershell/Test-PlatformHealth.ps1 -ResourceGroupName "rg-cyber-sre-dev"
```

## Common issues

| Symptom | Likely cause | Investigation and recovery |
| --- | --- | --- |
| `terraform init` cannot configure the backend | Incorrect state account/container values or missing state access. | Verify backend names, selected subscription, and RBAC on the state container. Re-run `terraform init` with the correct backend configuration. |
| `terraform validate` or `plan` fails on credentials | No valid Azure login or CI/CD identity is not configured. | Run `az login`, confirm `az account show`, and ensure the automation identity has the required Azure RBAC roles. |
| Storage account or Key Vault name is unavailable | `unique_suffix` is not globally unique or violates naming constraints. | Change the suffix to lowercase alphanumeric characters that produce a unique name; review the new plan. |
| Role-assignment creation fails | The deployer cannot create Azure RBAC assignments. | Request `Owner` or `User Access Administrator` at the required scope, then rerun the reviewed plan. |
| Data Factory cannot read/write ADLS Gen2 | Missing/incorrect managed-identity role, incorrect linked service, or network restriction. | Confirm the factory’s principal ID and `Storage Blob Data Contributor` assignment at storage scope; inspect Data Factory activity output and storage networking. |
| Health script reports `DEGRADED` | Authentication failed, the resource group does not exist, or no Data Factory/Log Analytics workspace is found. | Read the per-check message printed by the script, correct the named resource group or access, then rerun it. |
| A pipeline applies an unexpected plan | Variable source, backend key, or subscription selection differs between jobs. | Stop the apply. Verify the state key, variable inputs, identity, and plan artifact. Initialise state and create a new reviewed plan if uncertain. |
| State is locked | Another Terraform operation is active or was interrupted. | Confirm no legitimate operation is running. Resolve the active run first; only use force-unlock with the exact lock ID and change approval. |

## Useful Azure checks

```bash
az account show --output table
az resource list --resource-group rg-cyber-sre-dev --output table
az role assignment list \
  --scope "/subscriptions/<subscription-id>/resourceGroups/rg-cyber-sre-dev/providers/Microsoft.Storage/storageAccounts/stcybersre<suffix>" \
  --output table
```

For Data Factory failures, inspect Monitor > Pipeline runs and activity output in the Azure portal. For platform/control-plane failures, inspect the resource group Activity Log. The repository has no diagnostic settings or KQL content yet, so resource logs will not automatically appear in the deployed Log Analytics workspace until that configuration is added.

## Escalation criteria

Escalate using the [incident runbook](../incident/runbook.md) when ingestion is interrupted, privileged access may be affected, data loss is suspected, or a production security alert cannot be triaged within the agreed service objective. Record commands run, resource IDs, timestamps in UTC, impact, and all changes made.
